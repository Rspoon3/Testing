import CryptoKit
import Foundation
import GRDB
import SQLiteData

/// Minimal SQLiteData-backed repository that persists wrapped keys and encrypted item fields.
///
/// Hierarchy:
/// ARK -> VaultKey -> ItemKey -> Item field ciphertext
final class EnvelopeStore {
    /// Store-level errors.
    enum StoreError: Error {
        case vaultNotFound
        case itemNotFound
        case secretFieldNotFound
        case invalidCredential
        case invalidSecretField
        case invalidAttribute
        case unsupportedItemType
    }

    /// Backing SQLite database connection.
    let database: DatabaseQueue
    /// Account root key available in memory for current unlock session.
    let ark: SymmetricKey
    /// Identifier of the account root key in use for this session.
    let arkKeyID: String

    /// Creates a store with an unlocked ARK.
    init(
        database: DatabaseQueue,
        ark: SymmetricKey,
        arkKeyID: String = EnvelopeKeyID.implicitAccountARK
    ) {
        self.database = database
        self.ark = ark
        self.arkKeyID = arkKeyID
    }

    /// Opens a persistent SQLite database and migrates the envelope schema.
    static func openDatabase(at url: URL) throws -> DatabaseQueue {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let database = try DatabaseQueue(path: url.path)
        var migrator = DatabaseMigrator()
        #if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("Create account metadata and envelope tables") { db in
            try #sql(
                """
                CREATE TABLE "accountRootWrapRows" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "recoverySalt" BLOB NOT NULL,
                  "arkKeyID" TEXT NOT NULL CHECK (length("arkKeyID") > 0),
                  "recoveryWrappedByKeyID" TEXT NOT NULL CHECK (length("recoveryWrappedByKeyID") > 0),
                  "recoveryCryptoVersion" INTEGER NOT NULL CHECK ("recoveryCryptoVersion" > 0),
                  "recoveryAADVersion" INTEGER NOT NULL CHECK ("recoveryAADVersion" > 0),
                  "wrappedARKByRecovery" BLOB NOT NULL CHECK (length("wrappedARKByRecovery") > 0),
                  "syncWrappedByKeyID" TEXT CHECK ("syncWrappedByKeyID" IS NULL OR length("syncWrappedByKeyID") > 0),
                  "syncCryptoVersion" INTEGER CHECK ("syncCryptoVersion" IS NULL OR "syncCryptoVersion" > 0),
                  "syncAADVersion" INTEGER CHECK ("syncAADVersion" IS NULL OR "syncAADVersion" > 0),
                  "wrappedARKBySync" BLOB CHECK ("wrappedARKBySync" IS NULL OR length("wrappedARKBySync") > 0),
                  CHECK (
                    ("wrappedARKBySync" IS NULL AND "syncWrappedByKeyID" IS NULL AND "syncCryptoVersion" IS NULL AND "syncAADVersion" IS NULL)
                    OR
                    ("wrappedARKBySync" IS NOT NULL AND "syncWrappedByKeyID" IS NOT NULL AND "syncCryptoVersion" IS NOT NULL AND "syncAADVersion" IS NOT NULL)
                  )
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "deviceEnrollmentRows" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "accountID" TEXT NOT NULL REFERENCES "accountRootWrapRows"("id") ON DELETE CASCADE,
                  "arkKeyID" TEXT NOT NULL CHECK (length("arkKeyID") > 0),
                  "wrappedByKeyID" TEXT NOT NULL CHECK (length("wrappedByKeyID") > 0),
                  "cryptoVersion" INTEGER NOT NULL CHECK ("cryptoVersion" > 0),
                  "aadVersion" INTEGER NOT NULL CHECK ("aadVersion" > 0),
                  "wrappedARKByDevice" BLOB NOT NULL CHECK (length("wrappedARKByDevice") > 0)
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "vaults" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "name" TEXT NOT NULL CHECK (length("name") > 0),
                  "keyID" TEXT NOT NULL CHECK (length("keyID") > 0),
                  "wrappedByKeyID" TEXT NOT NULL CHECK (length("wrappedByKeyID") > 0),
                  "cryptoVersion" INTEGER NOT NULL CHECK ("cryptoVersion" > 0),
                  "aadVersion" INTEGER NOT NULL CHECK ("aadVersion" > 0),
                  "wrappedVaultKeyByARK" BLOB NOT NULL CHECK (length("wrappedVaultKeyByARK") > 0)
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "vaultItems" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "vaultID" TEXT NOT NULL REFERENCES "vaults"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL CHECK (length("title") > 0),
                  "type" TEXT NOT NULL,
                  "payloadVersion" INTEGER NOT NULL CHECK ("payloadVersion" > 0),
                  "keyID" TEXT NOT NULL CHECK (length("keyID") > 0),
                  "wrappedByKeyID" TEXT NOT NULL CHECK (length("wrappedByKeyID") > 0),
                  "cryptoVersion" INTEGER NOT NULL CHECK ("cryptoVersion" > 0),
                  "aadVersion" INTEGER NOT NULL CHECK ("aadVersion" > 0),
                  "wrappedItemKeyByVaultKey" BLOB NOT NULL CHECK (length("wrappedItemKeyByVaultKey") > 0),
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_vaultItems_on_vaultID" ON "vaultItems"("vaultID")
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "genericItemSecretFields" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "itemID" TEXT NOT NULL REFERENCES "vaultItems"("id") ON DELETE CASCADE,
                  "fieldName" TEXT NOT NULL CHECK (length("fieldName") > 0),
                  "keyID" TEXT NOT NULL CHECK (length("keyID") > 0),
                  "wrappedByKeyID" TEXT NOT NULL CHECK (length("wrappedByKeyID") > 0),
                  "cryptoVersion" INTEGER NOT NULL CHECK ("cryptoVersion" > 0),
                  "aadVersion" INTEGER NOT NULL CHECK ("aadVersion" > 0),
                  "ciphertext" BLOB NOT NULL CHECK (length("ciphertext") > 0),
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_genericItemSecretFields_on_itemID" ON "genericItemSecretFields"("itemID")
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "recoveryAttemptRows" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "consecutiveFailures" INTEGER NOT NULL CHECK ("consecutiveFailures" >= 0),
                  "lastAttemptAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Add credential attributes table") { db in
            try #sql(
                """
                CREATE TABLE "credentialAttributes" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "credentialID" TEXT NOT NULL REFERENCES "vaultItems"("id") ON DELETE CASCADE,
                  "kindRawValue" TEXT NOT NULL,
                  "name" TEXT NOT NULL,
                  "value" TEXT NOT NULL,
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_credentialAttributes_on_credentialID" ON "credentialAttributes"("credentialID")
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Add credential secret files table") { db in
            try #sql(
                """
                CREATE TABLE "credentialSecretFiles" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "credentialID" TEXT NOT NULL REFERENCES "vaultItems"("id") ON DELETE CASCADE,
                  "label" TEXT NOT NULL CHECK (length("label") > 0),
                  "fileName" TEXT NOT NULL CHECK (length("fileName") > 0),
                  "mimeType" TEXT,
                  "keyID" TEXT NOT NULL CHECK (length("keyID") > 0),
                  "wrappedByKeyID" TEXT NOT NULL CHECK (length("wrappedByKeyID") > 0),
                  "cryptoVersion" INTEGER NOT NULL CHECK ("cryptoVersion" > 0),
                  "aadVersion" INTEGER NOT NULL CHECK ("aadVersion" > 0),
                  "ciphertext" BLOB NOT NULL CHECK (length("ciphertext") > 0),
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_credentialSecretFiles_on_credentialID" ON "credentialSecretFiles"("credentialID")
                """
            )
            .execute(db)
        }

        try migrator.migrate(database)
        applyFileProtection(at: url)
        return database
    }

    /// Applies `FileProtectionType.complete` to the database file and its parent directory.
    ///
    /// This makes the file inaccessible when the device is locked, protecting plaintext
    /// metadata such as vault names and credential labels.
    private static func applyFileProtection(at url: URL) {
        let fileManager = FileManager.default
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.complete
        ]
        try? fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        try? fileManager.setAttributes(attributes, ofItemAtPath: url.deletingLastPathComponent().path)
    }

    /// Creates a vault and generates a new vault key wrapped by ARK.
    func createVault(name: String) throws -> Vault.ID {
        let vaultID = UUID()
        let vaultKey = SymmetricKey(size: .bits256)
        let vaultKeyID = EnvelopeKeyID.vaultKey(vaultID: vaultID)
        let wrappedVaultKey = try EnvelopeCrypto.wrapKey(
            vaultKey,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vaultID, aadVersion: EnvelopeKeyID.aadVersion),
            cryptoVersion: EnvelopeKeyID.cryptoVersion
        )

        let vault = Vault(
            id: vaultID,
            name: name,
            keyID: vaultKeyID,
            wrappedByKeyID: arkKeyID,
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            aadVersion: EnvelopeKeyID.aadVersion,
            wrappedVaultKeyByARK: wrappedVaultKey
        )
        try database.write { db in
            try Vault.insert {
                vault
            }
            .execute(db)
        }
        return vaultID
    }

    /// Creates a credential with at least one secret field.
    ///
    /// All rows are inserted in a single transaction so a crash cannot leave an
    /// orphaned credential without its initial secret.
    func createCredential(
        vaultID: Vault.ID,
        label: String,
        type: VaultItemType = .genericSecret,
        initialSecretLabel: String,
        initialSecretPlaintext: Data,
        environment: String? = nil,
        links: [String] = [],
        associatedEmails: [String] = [],
        notes: String? = nil,
        payloadVersion: Int = 1
    ) throws -> (credentialID: Credential.ID, initialSecretFieldID: Secret.ID) {
        guard !label.trimmedForValidation.isEmpty else {
            throw StoreError.invalidCredential
        }
        guard !initialSecretLabel.trimmedForValidation.isEmpty else {
            throw StoreError.invalidSecretField
        }

        // --- Crypto (no DB writes yet) ---

        let vault = try loadVault(vaultID: vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vaultID, aadVersion: vault.aadVersion),
            cryptoVersion: vault.cryptoVersion
        )

        let itemID = UUID()
        let itemKeyID = EnvelopeKeyID.itemKey(itemID: itemID)
        let itemKey = SymmetricKey(size: .bits256)
        let wrappedItemKey = try EnvelopeCrypto.wrapKey(
            itemKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.itemKey(vaultID: vaultID, itemID: itemID, aadVersion: EnvelopeKeyID.aadVersion),
            cryptoVersion: EnvelopeKeyID.cryptoVersion
        )

        let credential = VaultItem(
            id: itemID,
            vaultID: vaultID,
            title: label,
            type: type,
            payloadVersion: payloadVersion,
            keyID: itemKeyID,
            wrappedByKeyID: vault.keyID,
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            aadVersion: EnvelopeKeyID.aadVersion,
            wrappedItemKeyByVaultKey: wrappedItemKey
        )

        let fieldID = UUID()
        let fieldCiphertext = try EnvelopeCrypto.seal(
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

        let field = GenericItemSecretField(
            id: fieldID,
            itemID: itemID,
            fieldName: initialSecretLabel,
            keyID: itemKeyID,
            wrappedByKeyID: vault.keyID,
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            aadVersion: EnvelopeKeyID.aadVersion,
            ciphertext: fieldCiphertext
        )

        let attributeRows = buildAttributeRows(
            credentialID: itemID,
            environment: environment,
            links: links,
            associatedEmails: associatedEmails,
            notes: notes
        )

        // --- Single atomic write ---

        try database.write { db in
            try VaultItem.insert { credential }.execute(db)
            try GenericItemSecretField.insert { field }.execute(db)
            for attribute in attributeRows {
                try CredentialAttribute.insert { attribute }.execute(db)
            }
        }

        return (itemID, fieldID)
    }

    /// Creates a credential row and wraps a per-credential key with the containing vault key.
    ///
    /// Use this only when a secret field will be inserted immediately afterwards.
    func createCredential(vaultID: Vault.ID, label: String) throws -> Credential.ID {
        guard !label.trimmedForValidation.isEmpty else {
            throw StoreError.invalidCredential
        }
        return try createCredentialRecord(vaultID: vaultID, label: label, type: .genericSecret)
    }

    /// Internal credential row creation helper used by all creation entry points.
    private func createCredentialRecord(
        vaultID: Vault.ID,
        label: String,
        type: VaultItemType,
        payloadVersion: Int = 1
    ) throws -> Credential.ID {
        let vault = try loadVault(vaultID: vaultID)
        let vaultKeyID = vault.keyID
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vaultID, aadVersion: vault.aadVersion),
            cryptoVersion: vault.cryptoVersion
        )

        let itemID = UUID()
        let itemKeyID = EnvelopeKeyID.itemKey(itemID: itemID)
        let itemKey = SymmetricKey(size: .bits256)
        let wrappedItemKey = try EnvelopeCrypto.wrapKey(
            itemKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.itemKey(vaultID: vaultID, itemID: itemID, aadVersion: EnvelopeKeyID.aadVersion),
            cryptoVersion: EnvelopeKeyID.cryptoVersion
        )

        let credential = VaultItem(
            id: itemID,
            vaultID: vaultID,
            title: label,
            type: type,
            payloadVersion: payloadVersion,
            keyID: itemKeyID,
            wrappedByKeyID: vaultKeyID,
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            aadVersion: EnvelopeKeyID.aadVersion,
            wrappedItemKeyByVaultKey: wrappedItemKey
        )
        try database.write { db in
            try VaultItem.insert {
                credential
            }
            .execute(db)
        }
        return itemID
    }

    /// Encrypts and stores a secret under the credential key.
    func addSecret(credentialID: Credential.ID, name: String, plaintext: Data) throws -> Secret.ID {
        try addSecretField(credentialID: credentialID, label: name, plaintext: plaintext)
    }

    /// Encrypts and stores one secret field value for a credential.
    func addSecretField(
        credentialID: Credential.ID,
        label: String,
        plaintext: Data,
        cryptoVersion: Int = 1,
        aadVersion: Int = EnvelopeKeyID.aadVersion
    ) throws -> CredentialSecretField.ID {
        guard !label.trimmedForValidation.isEmpty else {
            throw StoreError.invalidSecretField
        }

        let (item, _, itemKey) = try loadItemAndKey(itemID: credentialID)
        let fieldID = UUID()
        let ciphertext = try EnvelopeCrypto.seal(
            plaintext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: item.id,
                fieldID: fieldID,
                cryptoVersion: cryptoVersion,
                aadVersion: aadVersion
            ),
            cryptoVersion: cryptoVersion
        )

        let field = GenericItemSecretField(
            id: fieldID,
            itemID: credentialID,
            fieldName: label,
            keyID: item.keyID,
            wrappedByKeyID: item.wrappedByKeyID,
            cryptoVersion: cryptoVersion,
            aadVersion: aadVersion,
            ciphertext: ciphertext
        )
        try database.write { db in
            try GenericItemSecretField.insert {
                field
            }
            .execute(db)
        }
        return fieldID
    }

    /// Encrypts and stores one credential file payload.
    func addSecretFile(
        credentialID: Credential.ID,
        label: String,
        fileName: String,
        mimeType: String? = nil,
        plaintext: Data,
        cryptoVersion: Int = 1,
        aadVersion: Int = EnvelopeKeyID.aadVersion
    ) throws -> CredentialSecretFile.ID {
        guard !label.trimmedForValidation.isEmpty else {
            throw StoreError.invalidSecretField
        }
        guard !fileName.trimmedForValidation.isEmpty else {
            throw StoreError.invalidSecretField
        }

        let (item, _, itemKey) = try loadItemAndKey(itemID: credentialID)
        let fileID = UUID()
        let ciphertext = try EnvelopeCrypto.seal(
            plaintext,
            using: itemKey,
            aad: EnvelopeAAD.itemFile(
                itemID: item.id,
                fileID: fileID,
                cryptoVersion: cryptoVersion,
                aadVersion: aadVersion
            ),
            cryptoVersion: cryptoVersion
        )

        let secretFile = CredentialSecretFile(
            id: fileID,
            credentialID: credentialID,
            label: label,
            fileName: fileName,
            mimeType: mimeType?.trimmedForValidation,
            keyID: item.keyID,
            wrappedByKeyID: item.wrappedByKeyID,
            cryptoVersion: cryptoVersion,
            aadVersion: aadVersion,
            ciphertext: ciphertext
        )
        try database.write { db in
            try CredentialSecretFile.insert {
                secretFile
            }
            .execute(db)
        }
        return fileID
    }

    /// Stores one non-secret metadata value for a credential.
    func addCredentialAttribute(
        credentialID: Credential.ID,
        kind: CredentialAttributeKind,
        name: String? = nil,
        value: String
    ) throws -> CredentialAttribute.ID {
        let normalizedValue = value.trimmedForValidation
        guard !normalizedValue.isEmpty else {
            throw StoreError.invalidAttribute
        }
        let normalizedName = name?.trimmedForValidation ?? ""

        let attributeID = UUID()
        let attribute = CredentialAttribute(
            id: attributeID,
            credentialID: credentialID,
            kindRawValue: kind.rawValue,
            name: normalizedName.isEmpty ? kind.defaultAttributeName : normalizedName,
            value: normalizedValue
        )
        try database.write { db in
            try CredentialAttribute.insert {
                attribute
            }
            .execute(db)
        }
        return attributeID
    }

    /// Bulk metadata helper for common optional credential fields.
    func addCredentialAttributes(
        credentialID: Credential.ID,
        environment: String? = nil,
        links: [String] = [],
        associatedEmails: [String] = [],
        notes: String? = nil
    ) throws {
        if let environment, !environment.trimmedForValidation.isEmpty {
            _ = try addCredentialAttribute(
                credentialID: credentialID,
                kind: .environment,
                value: environment
            )
        }
        for link in links where !link.trimmedForValidation.isEmpty {
            _ = try addCredentialAttribute(
                credentialID: credentialID,
                kind: .link,
                value: link
            )
        }
        for email in associatedEmails where !email.trimmedForValidation.isEmpty {
            _ = try addCredentialAttribute(
                credentialID: credentialID,
                kind: .associatedEmail,
                value: email
            )
        }
        if let notes, !notes.trimmedForValidation.isEmpty {
            _ = try addCredentialAttribute(
                credentialID: credentialID,
                kind: .note,
                value: notes
            )
        }
    }

    /// Reveals a secret by unwrapping keys down the hierarchy and decrypting payload.
    func revealSecret(secretID: Secret.ID) throws -> Data {
        try revealSecretField(fieldID: secretID)
    }

    /// Reveals one generic item field by decrypting with the owning item key.
    func revealSecretField(fieldID: GenericItemSecretField.ID) throws -> Data {
        let field = try loadSecretField(fieldID: fieldID)
        let (item, _, itemKey) = try loadItemAndKey(itemID: field.itemID)
        return try EnvelopeCrypto.open(
            field.ciphertext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: item.id,
                fieldID: field.id,
                cryptoVersion: field.cryptoVersion,
                aadVersion: field.aadVersion
            ),
            cryptoVersion: field.cryptoVersion
        )
    }

    /// Reveals one encrypted credential file payload.
    func revealSecretFile(fileID: CredentialSecretFile.ID) throws -> Data {
        let secretFile = try loadSecretFile(fileID: fileID)
        let (item, _, itemKey) = try loadItemAndKey(itemID: secretFile.credentialID)
        return try EnvelopeCrypto.open(
            secretFile.ciphertext,
            using: itemKey,
            aad: EnvelopeAAD.itemFile(
                itemID: item.id,
                fileID: secretFile.id,
                cryptoVersion: secretFile.cryptoVersion,
                aadVersion: secretFile.aadVersion
            ),
            cryptoVersion: secretFile.cryptoVersion
        )
    }

    /// Loads one vault row by ID.
    func loadVault(vaultID: Vault.ID) throws -> Vault {
        guard let vault = try database.read({ db in
            try Vault.where { $0.id.eq(vaultID) }.fetchOne(db)
        }) else {
            throw StoreError.vaultNotFound
        }
        return vault
    }

    /// Loads one item and unwraps its item key.
    func loadItemAndKey(itemID: VaultItem.ID) throws -> (VaultItem, VaultItemType, SymmetricKey) {
        guard let item = try database.read({ db in
            try VaultItem.where { $0.id.eq(itemID) }.fetchOne(db)
        }) else {
            throw StoreError.itemNotFound
        }
        let itemType = item.type

        let vault = try loadVault(vaultID: item.vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vault.id, aadVersion: vault.aadVersion),
            cryptoVersion: vault.cryptoVersion
        )
        let itemKey = try EnvelopeCrypto.unwrapKey(
            item.wrappedItemKeyByVaultKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.itemKey(vaultID: vault.id, itemID: item.id, aadVersion: item.aadVersion),
            cryptoVersion: item.cryptoVersion
        )

        return (item, itemType, itemKey)
    }

    /// Loads one generic secret field row by ID.
    private func loadSecretField(fieldID: GenericItemSecretField.ID) throws -> GenericItemSecretField {
        guard let secret = try database.read({ db in
            try GenericItemSecretField.where { $0.id.eq(fieldID) }.fetchOne(db)
        }) else {
            throw StoreError.secretFieldNotFound
        }
        return secret
    }

    /// Loads one credential secret file row by ID.
    private func loadSecretFile(fileID: CredentialSecretFile.ID) throws -> CredentialSecretFile {
        guard let secretFile = try database.read({ db in
            try CredentialSecretFile.where { $0.id.eq(fileID) }.fetchOne(db)
        }) else {
            throw StoreError.secretFieldNotFound
        }
        return secretFile
    }

    /// Builds attribute rows without persisting, for use in atomic writes.
    private func buildAttributeRows(
        credentialID: Credential.ID,
        environment: String?,
        links: [String],
        associatedEmails: [String],
        notes: String?
    ) -> [CredentialAttribute] {
        var rows: [CredentialAttribute] = []

        if let environment, !environment.trimmedForValidation.isEmpty {
            rows.append(CredentialAttribute(
                id: UUID(),
                credentialID: credentialID,
                kindRawValue: CredentialAttributeKind.environment.rawValue,
                name: CredentialAttributeKind.environment.defaultAttributeName,
                value: environment.trimmedForValidation
            ))
        }
        for link in links where !link.trimmedForValidation.isEmpty {
            rows.append(CredentialAttribute(
                id: UUID(),
                credentialID: credentialID,
                kindRawValue: CredentialAttributeKind.link.rawValue,
                name: CredentialAttributeKind.link.defaultAttributeName,
                value: link.trimmedForValidation
            ))
        }
        for email in associatedEmails where !email.trimmedForValidation.isEmpty {
            rows.append(CredentialAttribute(
                id: UUID(),
                credentialID: credentialID,
                kindRawValue: CredentialAttributeKind.associatedEmail.rawValue,
                name: CredentialAttributeKind.associatedEmail.defaultAttributeName,
                value: email.trimmedForValidation
            ))
        }
        if let notes, !notes.trimmedForValidation.isEmpty {
            rows.append(CredentialAttribute(
                id: UUID(),
                credentialID: credentialID,
                kindRawValue: CredentialAttributeKind.note.rawValue,
                name: CredentialAttributeKind.note.defaultAttributeName,
                value: notes.trimmedForValidation
            ))
        }

        return rows
    }

}

extension CredentialAttributeKind {
    var defaultAttributeName: String {
        switch self {
        case .environment:
            return "environment"
        case .link:
            return "link"
        case .associatedEmail:
            return "email"
        case .note:
            return "note"
        case .custom:
            return "custom"
        }
    }
}

private extension String {
    var trimmedForValidation: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
