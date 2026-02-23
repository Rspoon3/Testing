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
        case typedItemMetadataNotFound
        case unsupportedItemType
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
                CREATE TABLE "vaultItems" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "vaultID" TEXT NOT NULL REFERENCES "vaults"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL,
                  "typeRawValue" TEXT NOT NULL,
                  "payloadVersion" INTEGER NOT NULL,
                  "wrappedItemKeyByVaultKey" BLOB NOT NULL,
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
                  "fieldName" TEXT NOT NULL,
                  "cryptoVersion" INTEGER NOT NULL,
                  "ciphertext" BLOB NOT NULL,
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
        }

        registerTypedItemMigrations(on: &migrator)

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

    /// Creates a generic credential item and generates an item key wrapped by its vault key.
    func createCredential(vaultID: Vault.ID, label: String) throws -> Credential.ID {
        try createItem(vaultID: vaultID, title: label, type: .genericSecret)
    }

    /// Creates a generic item entry and wraps a per-item key with the containing vault key.
    func createItem(
        vaultID: Vault.ID,
        title: String,
        type: VaultItemType,
        payloadVersion: Int = 1
    ) throws -> VaultItem.ID {
        let vault = try loadVault(vaultID: vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vaultID)
        )

        let itemID = UUID()
        let itemKey = SymmetricKey(size: .bits256)
        let wrappedItemKey = try EnvelopeCrypto.wrapKey(
            itemKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.itemKey(vaultID: vaultID, itemID: itemID)
        )

        let item = VaultItem(
            id: itemID,
            vaultID: vaultID,
            title: title,
            typeRawValue: type.rawValue,
            payloadVersion: payloadVersion,
            wrappedItemKeyByVaultKey: wrappedItemKey
        )
        try database.write { db in
            try VaultItem.insert {
                item
            }
            .execute(db)
        }
        return itemID
    }

    /// Encrypts and stores a secret under the credential key.
    func addSecret(credentialID: Credential.ID, name: String, plaintext: Data) throws -> Secret.ID {
        try addSecretField(itemID: credentialID, fieldName: name, plaintext: plaintext)
    }

    /// Encrypts and stores one field value for a generic item.
    func addSecretField(
        itemID: VaultItem.ID,
        fieldName: String,
        plaintext: Data,
        cryptoVersion: Int = 1
    ) throws -> GenericItemSecretField.ID {
        let (item, itemType, itemKey) = try loadItemAndKey(itemID: itemID)
        let ciphertext = try EnvelopeCrypto.seal(
            plaintext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: item.id,
                itemType: itemType,
                fieldName: fieldName,
                cryptoVersion: cryptoVersion
            )
        )

        let fieldID = UUID()
        let field = GenericItemSecretField(
            id: fieldID,
            itemID: itemID,
            fieldName: fieldName,
            cryptoVersion: cryptoVersion,
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

    /// Reveals a secret by unwrapping keys down the hierarchy and decrypting payload.
    func revealSecret(secretID: Secret.ID) throws -> Data {
        try revealSecretField(fieldID: secretID)
    }

    /// Reveals one generic item field by decrypting with the owning item key.
    func revealSecretField(fieldID: GenericItemSecretField.ID) throws -> Data {
        let field = try loadSecretField(fieldID: fieldID)
        let (item, itemType, itemKey) = try loadItemAndKey(itemID: field.itemID)
        return try EnvelopeCrypto.open(
            field.ciphertext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: item.id,
                itemType: itemType,
                fieldName: field.fieldName,
                cryptoVersion: field.cryptoVersion
            )
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
        guard let itemType = VaultItemType(rawValue: item.typeRawValue) else {
            throw StoreError.unsupportedItemType
        }

        let vault = try loadVault(vaultID: item.vaultID)
        let vaultKey = try EnvelopeCrypto.unwrapKey(
            vault.wrappedVaultKeyByARK,
            wrappingKey: ark,
            aad: EnvelopeAAD.vaultKey(vaultID: vault.id)
        )
        let itemKey = try EnvelopeCrypto.unwrapKey(
            item.wrappedItemKeyByVaultKey,
            wrappingKey: vaultKey,
            aad: EnvelopeAAD.itemKey(vaultID: vault.id, itemID: item.id)
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

}
