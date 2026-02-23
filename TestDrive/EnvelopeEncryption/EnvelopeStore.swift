import CryptoKit
import Foundation
import GRDB
import SQLiteData

/// Minimal SQLiteData-backed repository that persists wrapped keys and encrypted secrets.
///
/// Hierarchy:
/// ARK -> VaultKey -> CredentialKey -> Secret ciphertext
final class EnvelopeStore {
    /// Store-level errors.
    enum StoreError: Error {
        case vaultNotFound
        case credentialNotFound
        case secretNotFound
    }

    /// Backing SQLite database connection.
    let database: DatabaseQueue
    /// Account root key available in memory for current unlock session.
    let ark: SymmetricKey

    /// Creates a store with an unlocked ARK.
    init(database: DatabaseQueue, ark: SymmetricKey) {
        self.database = database
        self.ark = ark
    }

    /// Opens a persistent SQLite database and migrates the envelope schema.
    static func openDatabase(at url: URL) throws -> DatabaseQueue {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let database = try DatabaseQueue(path: url.path)
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create account metadata and envelope tables") { db in
            try #sql(
                """
                CREATE TABLE "accountRootWrapRows" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "recoverySalt" BLOB NOT NULL,
                  "wrappedARKByRecovery" BLOB NOT NULL,
                  "wrappedARKBySync" BLOB
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "deviceEnrollmentRows" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "accountID" TEXT NOT NULL REFERENCES "accountRootWrapRows"("id") ON DELETE CASCADE,
                  "wrappedARKByDevice" BLOB NOT NULL
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "vaults" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "name" TEXT NOT NULL,
                  "wrappedVaultKeyByARK" BLOB NOT NULL
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "credentials" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "vaultID" TEXT NOT NULL REFERENCES "vaults"("id") ON DELETE CASCADE,
                  "label" TEXT NOT NULL,
                  "wrappedCredentialKeyByVaultKey" BLOB NOT NULL
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "secrets" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "credentialID" TEXT NOT NULL REFERENCES "credentials"("id") ON DELETE CASCADE,
                  "name" TEXT NOT NULL,
                  "ciphertext" BLOB NOT NULL
                ) STRICT
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
        let wrappedVaultKey = try EnvelopeCrypto.wrapKey(
            vaultKey,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vaultID)
        )

        let vault = Vault(id: vaultID, name: name, wrappedVaultKeyByARK: wrappedVaultKey)
        try database.write { db in
            try Vault.insert {
                vault
            }
            .execute(db)
        }
        return vaultID
    }

    /// Creates a credential and generates a credential key wrapped by its vault key.
    func createCredential(vaultID: Vault.ID, label: String) throws -> Credential.ID {
        let vault = try loadVault(vaultID: vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vaultID)
        )

        let credentialID = UUID()
        let credentialKey = SymmetricKey(size: .bits256)
        let wrappedCredentialKey = try EnvelopeCrypto.wrapKey(
            credentialKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.credentialKey(vaultID: vaultID, credentialID: credentialID)
        )

        let credential = Credential(
            id: credentialID,
            vaultID: vaultID,
            label: label,
            wrappedCredentialKeyByVaultKey: wrappedCredentialKey
        )
        try database.write { db in
            try Credential.insert {
                credential
            }
            .execute(db)
        }
        return credentialID
    }

    /// Encrypts and stores a secret under the credential key.
    func addSecret(credentialID: Credential.ID, name: String, plaintext: Data) throws -> Secret.ID {
        let (credential, credentialKey) = try loadCredentialAndKey(credentialID: credentialID)
        let ciphertext = try EnvelopeCrypto.seal(
            plaintext,
            using: credentialKey,
            aad: EnvelopeAAD.secret(credentialID: credential.id, secretName: name)
        )

        let secretID = UUID()
        let secret = Secret(
            id: secretID,
            credentialID: credentialID,
            name: name,
            ciphertext: ciphertext
        )
        try database.write { db in
            try Secret.insert {
                secret
            }
            .execute(db)
        }
        return secretID
    }

    /// Reveals a secret by unwrapping keys down the hierarchy and decrypting payload.
    func revealSecret(secretID: Secret.ID) throws -> Data {
        let secret = try loadSecret(secretID: secretID)
        let (_, credentialKey) = try loadCredentialAndKey(credentialID: secret.credentialID)
        return try EnvelopeCrypto.open(
            secret.ciphertext,
            using: credentialKey,
            aad: EnvelopeAAD.secret(credentialID: secret.credentialID, secretName: secret.name)
        )
    }

    /// Loads one vault row by ID.
    private func loadVault(vaultID: Vault.ID) throws -> Vault {
        guard let vault = try database.read({ db in
            try Vault.where { $0.id.eq(vaultID) }.fetchOne(db)
        }) else {
            throw StoreError.vaultNotFound
        }
        return vault
    }

    /// Loads a credential and unwraps its credential key.
    private func loadCredentialAndKey(credentialID: Credential.ID) throws -> (Credential, SymmetricKey) {
        guard let credential = try database.read({ db in
            try Credential.where { $0.id.eq(credentialID) }.fetchOne(db)
        }) else {
            throw StoreError.credentialNotFound
        }

        let vault = try loadVault(vaultID: credential.vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vault.id)
        )
        let credentialKey = try EnvelopeCrypto.unwrapKey(
            credential.wrappedCredentialKeyByVaultKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.credentialKey(vaultID: vault.id, credentialID: credential.id)
        )

        return (credential, credentialKey)
    }

    /// Loads one secret row by ID.
    private func loadSecret(secretID: Secret.ID) throws -> Secret {
        guard let secret = try database.read({ db in
            try Secret.where { $0.id.eq(secretID) }.fetchOne(db)
        }) else {
            throw StoreError.secretNotFound
        }
        return secret
    }
}
