import CryptoKit
import Foundation

/// DB-agnostic envelope encryption engine.
///
/// Hierarchy:
/// ARK -> VaultKey -> ItemKey -> Secret field ciphertext
final class EnvelopeDomainStore {
    enum StoreError: Error {
        case vaultNotFound
        case credentialNotFound
        case secretFieldNotFound
        case invalidCredential
        case invalidSecretField
    }

    struct SharedVaultPackage: Sendable {
        var vault: PersistedVault
        var credentials: [PersistedCredential]
        var secretFields: [PersistedSecretField]
    }

    let persistence: any EnvelopeDomainPersisting
    let ark: SymmetricKey
    let arkKeyID: String
    private let now: () -> Date

    init(
        persistence: any EnvelopeDomainPersisting,
        ark: SymmetricKey,
        arkKeyID: String = EnvelopeKeyID.implicitAccountARK,
        now: @escaping () -> Date = { Date() }
    ) {
        self.persistence = persistence
        self.ark = ark
        self.arkKeyID = arkKeyID
        self.now = now
    }

    func createVault(name: String) throws -> UUID {
        let vaultID = UUID()
        let vaultKey = SymmetricKey(size: .bits256)
        let vaultKeyID = EnvelopeKeyID.vaultKey(vaultID: vaultID)
        let wrappedVaultKey = try EnvelopeCrypto.wrapKey(
            vaultKey,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(
                vaultID: vaultID,
                cryptoVersion: EnvelopeKeyID.cryptoVersion,
                aadVersion: EnvelopeKeyID.aadVersion
            ),
            cryptoVersion: EnvelopeKeyID.cryptoVersion
        )
        try persistence.upsertVault(PersistedVault(
            id: vaultID,
            name: name,
            keyID: vaultKeyID,
            wrappedByKeyID: arkKeyID,
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            aadVersion: EnvelopeKeyID.aadVersion,
            wrappedVaultKeyByARK: wrappedVaultKey
        ))
        return vaultID
    }

    func createCredential(
        vaultID: UUID,
        label: String,
        type: VaultItemType = .genericSecret,
        initialSecretLabel: String,
        initialSecretPlaintext: Data,
        payloadVersion: Int = 1
    ) throws -> (credentialID: UUID, initialSecretFieldID: UUID) {
        guard !label.trimmedForValidation.isEmpty else {
            throw StoreError.invalidCredential
        }
        guard !initialSecretLabel.trimmedForValidation.isEmpty else {
            throw StoreError.invalidSecretField
        }

        let vault = try loadVault(vaultID: vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(
                vaultID: vaultID,
                cryptoVersion: vault.cryptoVersion,
                aadVersion: vault.aadVersion
            ),
            cryptoVersion: vault.cryptoVersion
        )

        let itemID = UUID()
        let itemKey = SymmetricKey(size: .bits256)
        let itemKeyID = EnvelopeKeyID.itemKey(itemID: itemID)
        let wrappedItemKey = try EnvelopeCrypto.wrapKey(
            itemKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.itemKey(
                vaultID: vaultID,
                itemID: itemID,
                cryptoVersion: EnvelopeKeyID.cryptoVersion,
                aadVersion: EnvelopeKeyID.aadVersion
            ),
            cryptoVersion: EnvelopeKeyID.cryptoVersion
        )

        let timestamp = now()
        try persistence.upsertCredential(PersistedCredential(
            id: itemID,
            vaultID: vaultID,
            title: label,
            type: type,
            payloadVersion: payloadVersion,
            keyID: itemKeyID,
            wrappedByKeyID: vault.keyID,
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            aadVersion: EnvelopeKeyID.aadVersion,
            wrappedItemKeyByVaultKey: wrappedItemKey,
            createdAt: timestamp,
            updatedAt: timestamp
        ))

        let fieldID = UUID()
        let ciphertext = try EnvelopeCrypto.seal(
            initialSecretPlaintext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: itemID,
                fieldID: fieldID,
                cryptoVersion: EnvelopeKeyID.cryptoVersion,
                aadVersion: EnvelopeKeyID.aadVersion
            ),
            cryptoVersion: EnvelopeKeyID.cryptoVersion
        )
        try persistence.upsertSecretField(PersistedSecretField(
            id: fieldID,
            itemID: itemID,
            fieldName: initialSecretLabel,
            keyID: itemKeyID,
            wrappedByKeyID: vault.keyID,
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            aadVersion: EnvelopeKeyID.aadVersion,
            ciphertext: ciphertext,
            createdAt: timestamp,
            updatedAt: timestamp
        ))

        return (itemID, fieldID)
    }

    func addSecret(
        credentialID: UUID,
        name: String,
        plaintext: Data,
        cryptoVersion: Int = EnvelopeKeyID.cryptoVersion,
        aadVersion: Int = EnvelopeKeyID.aadVersion
    ) throws -> UUID {
        guard !name.trimmedForValidation.isEmpty else {
            throw StoreError.invalidSecretField
        }

        let (credential, itemKey) = try loadCredentialAndItemKey(credentialID: credentialID)
        let fieldID = UUID()
        let ciphertext = try EnvelopeCrypto.seal(
            plaintext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: credential.id,
                fieldID: fieldID,
                cryptoVersion: cryptoVersion,
                aadVersion: aadVersion
            ),
            cryptoVersion: cryptoVersion
        )

        let timestamp = now()
        try persistence.upsertSecretField(PersistedSecretField(
            id: fieldID,
            itemID: credentialID,
            fieldName: name,
            keyID: credential.keyID,
            wrappedByKeyID: credential.wrappedByKeyID,
            cryptoVersion: cryptoVersion,
            aadVersion: aadVersion,
            ciphertext: ciphertext,
            createdAt: timestamp,
            updatedAt: timestamp
        ))
        return fieldID
    }

    func revealSecret(secretID: UUID) throws -> Data {
        let field: PersistedSecretField
        do {
            field = try persistence.loadSecretField(id: secretID)
        } catch {
            throw StoreError.secretFieldNotFound
        }
        let (credential, itemKey) = try loadCredentialAndItemKey(credentialID: field.itemID)
        return try EnvelopeCrypto.open(
            field.ciphertext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: credential.id,
                fieldID: field.id,
                cryptoVersion: field.cryptoVersion,
                aadVersion: field.aadVersion
            ),
            cryptoVersion: field.cryptoVersion
        )
    }

    /// Creates a share package by re-wrapping the vault key for the recipient ARK.
    func makeSharedVaultPackage(
        vaultID: UUID,
        recipientARK: SymmetricKey,
        recipientARKKeyID: String
    ) throws -> SharedVaultPackage {
        let vault = try loadVault(vaultID: vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(
                vaultID: vault.id,
                cryptoVersion: vault.cryptoVersion,
                aadVersion: vault.aadVersion
            ),
            cryptoVersion: vault.cryptoVersion
        )
        let wrappedVaultKeyForRecipient = try EnvelopeCrypto.wrapKey(
            vaultKey,
            wrappingKey: recipientARK,
            aad: EnvelopeAAD.vaultKey(
                vaultID: vault.id,
                cryptoVersion: vault.cryptoVersion,
                aadVersion: vault.aadVersion
            ),
            cryptoVersion: vault.cryptoVersion
        )
        let recipientVault = PersistedVault(
            id: vault.id,
            name: vault.name,
            keyID: vault.keyID,
            wrappedByKeyID: recipientARKKeyID,
            cryptoVersion: vault.cryptoVersion,
            aadVersion: vault.aadVersion,
            wrappedVaultKeyByARK: wrappedVaultKeyForRecipient
        )

        let credentials = try persistence.loadCredentials(vaultID: vaultID)
        let secretFields = try credentials.flatMap { credential in
            try persistence.loadSecretFields(itemID: credential.id)
        }

        return SharedVaultPackage(
            vault: recipientVault,
            credentials: credentials,
            secretFields: secretFields
        )
    }

    /// Imports a share package as opaque encrypted records.
    func importSharedVaultPackage(_ package: SharedVaultPackage) throws {
        try persistence.upsertVault(package.vault)
        for credential in package.credentials {
            try persistence.upsertCredential(credential)
        }
        for field in package.secretFields {
            try persistence.upsertSecretField(field)
        }
    }

    private func loadVault(vaultID: UUID) throws -> PersistedVault {
        do {
            return try persistence.loadVault(id: vaultID)
        } catch {
            throw StoreError.vaultNotFound
        }
    }

    private func loadCredentialAndItemKey(credentialID: UUID) throws -> (PersistedCredential, SymmetricKey) {
        let credential: PersistedCredential
        do {
            credential = try persistence.loadCredential(id: credentialID)
        } catch {
            throw StoreError.credentialNotFound
        }

        let vault = try loadVault(vaultID: credential.vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(
                vaultID: vault.id,
                cryptoVersion: vault.cryptoVersion,
                aadVersion: vault.aadVersion
            ),
            cryptoVersion: vault.cryptoVersion
        )
        let itemKey = try EnvelopeCrypto.unwrapKey(
            credential.wrappedItemKeyByVaultKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.itemKey(
                vaultID: vault.id,
                itemID: credential.id,
                cryptoVersion: credential.cryptoVersion,
                aadVersion: credential.aadVersion
            ),
            cryptoVersion: credential.cryptoVersion
        )
        return (credential, itemKey)
    }
}

private extension String {
    var trimmedForValidation: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
