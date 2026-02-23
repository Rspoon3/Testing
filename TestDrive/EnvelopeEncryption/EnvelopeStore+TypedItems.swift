import Foundation
import GRDB
import SQLiteData

extension EnvelopeStore {
    /// Registers migrations for type-specific item tables.
    static func registerTypedItemMigrations(on migrator: inout DatabaseMigrator) {
        migrator.registerMigration("Add software license item tables") { db in
            try #sql(
                """
                CREATE TABLE "softwareLicenseItems" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "itemID" TEXT NOT NULL UNIQUE REFERENCES "vaultItems"("id") ON DELETE CASCADE,
                  "publisher" TEXT NOT NULL,
                  "productName" TEXT NOT NULL,
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_softwareLicenseItems_on_itemID" ON "softwareLicenseItems"("itemID")
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "softwareLicenseSecretFields" (
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
                CREATE INDEX "index_softwareLicenseSecretFields_on_itemID" ON "softwareLicenseSecretFields"("itemID")
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Add username/password item tables") { db in
            try #sql(
                """
                CREATE TABLE "usernamePasswordItems" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "itemID" TEXT NOT NULL UNIQUE REFERENCES "vaultItems"("id") ON DELETE CASCADE,
                  "service" TEXT NOT NULL,
                  "loginURL" TEXT,
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_usernamePasswordItems_on_itemID" ON "usernamePasswordItems"("itemID")
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "usernamePasswordSecretFields" (
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
                CREATE INDEX "index_usernamePasswordSecretFields_on_itemID" ON "usernamePasswordSecretFields"("itemID")
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Add personal access token item tables") { db in
            try #sql(
                """
                CREATE TABLE "personalAccessTokenItems" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "itemID" TEXT NOT NULL UNIQUE REFERENCES "vaultItems"("id") ON DELETE CASCADE,
                  "provider" TEXT NOT NULL,
                  "tokenName" TEXT NOT NULL,
                  "scopesHint" TEXT,
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_personalAccessTokenItems_on_itemID" ON "personalAccessTokenItems"("itemID")
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "personalAccessTokenSecretFields" (
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
                CREATE INDEX "index_personalAccessTokenSecretFields_on_itemID" ON "personalAccessTokenSecretFields"("itemID")
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Add database credential item tables") { db in
            try #sql(
                """
                CREATE TABLE "databaseCredentialItems" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "itemID" TEXT NOT NULL UNIQUE REFERENCES "vaultItems"("id") ON DELETE CASCADE,
                  "engine" TEXT NOT NULL,
                  "host" TEXT NOT NULL,
                  "port" INTEGER NOT NULL,
                  "databaseName" TEXT NOT NULL,
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_databaseCredentialItems_on_itemID" ON "databaseCredentialItems"("itemID")
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "databaseCredentialSecretFields" (
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
                CREATE INDEX "index_databaseCredentialSecretFields_on_itemID" ON "databaseCredentialSecretFields"("itemID")
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Add mobile release signing item tables") { db in
            try #sql(
                """
                CREATE TABLE "mobileReleaseSigningItems" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "itemID" TEXT NOT NULL UNIQUE REFERENCES "vaultItems"("id") ON DELETE CASCADE,
                  "platform" TEXT NOT NULL,
                  "appIdentifier" TEXT NOT NULL,
                  "teamOrOrgIdentifier" TEXT NOT NULL,
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_mobileReleaseSigningItems_on_itemID" ON "mobileReleaseSigningItems"("itemID")
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "mobileReleaseSigningSecretFields" (
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
                CREATE INDEX "index_mobileReleaseSigningSecretFields_on_itemID" ON "mobileReleaseSigningSecretFields"("itemID")
                """
            )
            .execute(db)
        }
    }

    /// Creates a software-license item with typed metadata.
    func createSoftwareLicense(
        vaultID: Vault.ID,
        title: String,
        publisher: String,
        productName: String,
        payloadVersion: Int = 1
    ) throws -> VaultItem.ID {
        let itemID = try createItem(
            vaultID: vaultID,
            title: title,
            type: .softwareLicense,
            payloadVersion: payloadVersion
        )

        let metadata = SoftwareLicenseItem(
            id: UUID(),
            itemID: itemID,
            publisher: publisher,
            productName: productName
        )
        try database.write { db in
            try SoftwareLicenseItem.insert {
                metadata
            }
            .execute(db)
        }
        return itemID
    }

    /// Encrypts and stores one field value for a software-license item.
    func addSoftwareLicenseField(
        itemID: VaultItem.ID,
        fieldName: String,
        plaintext: Data,
        cryptoVersion: Int = 1
    ) throws -> SoftwareLicenseSecretField.ID {
        _ = try loadSoftwareLicenseMetadata(itemID: itemID)
        let ciphertext = try sealTypedField(
            itemID: itemID,
            expectedType: .softwareLicense,
            fieldName: fieldName,
            plaintext: plaintext,
            cryptoVersion: cryptoVersion
        )

        let fieldID = UUID()
        let field = SoftwareLicenseSecretField(
            id: fieldID,
            itemID: itemID,
            fieldName: fieldName,
            cryptoVersion: cryptoVersion,
            ciphertext: ciphertext
        )
        try database.write { db in
            try SoftwareLicenseSecretField.insert {
                field
            }
            .execute(db)
        }
        return fieldID
    }

    /// Reveals one software-license field by decrypting with the owning item key.
    func revealSoftwareLicenseField(fieldID: SoftwareLicenseSecretField.ID) throws -> Data {
        guard let field = try database.read({ db in
            try SoftwareLicenseSecretField.where { $0.id.eq(fieldID) }.fetchOne(db)
        }) else {
            throw StoreError.secretFieldNotFound
        }
        return try openTypedField(
            itemID: field.itemID,
            expectedType: .softwareLicense,
            fieldName: field.fieldName,
            cryptoVersion: field.cryptoVersion,
            ciphertext: field.ciphertext
        )
    }

    /// Creates a username/password item with typed metadata.
    func createUsernamePassword(
        vaultID: Vault.ID,
        title: String,
        service: String,
        loginURL: String? = nil,
        payloadVersion: Int = 1
    ) throws -> VaultItem.ID {
        let itemID = try createItem(
            vaultID: vaultID,
            title: title,
            type: .usernamePassword,
            payloadVersion: payloadVersion
        )

        let metadata = UsernamePasswordItem(
            id: UUID(),
            itemID: itemID,
            service: service,
            loginURL: loginURL
        )
        try database.write { db in
            try UsernamePasswordItem.insert {
                metadata
            }
            .execute(db)
        }
        return itemID
    }

    /// Encrypts and stores one field value for a username/password item.
    func addUsernamePasswordField(
        itemID: VaultItem.ID,
        fieldName: String,
        plaintext: Data,
        cryptoVersion: Int = 1
    ) throws -> UsernamePasswordSecretField.ID {
        _ = try loadUsernamePasswordMetadata(itemID: itemID)
        let ciphertext = try sealTypedField(
            itemID: itemID,
            expectedType: .usernamePassword,
            fieldName: fieldName,
            plaintext: plaintext,
            cryptoVersion: cryptoVersion
        )

        let fieldID = UUID()
        let field = UsernamePasswordSecretField(
            id: fieldID,
            itemID: itemID,
            fieldName: fieldName,
            cryptoVersion: cryptoVersion,
            ciphertext: ciphertext
        )
        try database.write { db in
            try UsernamePasswordSecretField.insert {
                field
            }
            .execute(db)
        }
        return fieldID
    }

    /// Reveals one username/password field by decrypting with the owning item key.
    func revealUsernamePasswordField(fieldID: UsernamePasswordSecretField.ID) throws -> Data {
        guard let field = try database.read({ db in
            try UsernamePasswordSecretField.where { $0.id.eq(fieldID) }.fetchOne(db)
        }) else {
            throw StoreError.secretFieldNotFound
        }
        return try openTypedField(
            itemID: field.itemID,
            expectedType: .usernamePassword,
            fieldName: field.fieldName,
            cryptoVersion: field.cryptoVersion,
            ciphertext: field.ciphertext
        )
    }

    /// Creates a personal-access-token item with typed metadata.
    func createPersonalAccessToken(
        vaultID: Vault.ID,
        title: String,
        provider: String,
        tokenName: String,
        scopesHint: String? = nil,
        payloadVersion: Int = 1
    ) throws -> VaultItem.ID {
        let itemID = try createItem(
            vaultID: vaultID,
            title: title,
            type: .personalAccessToken,
            payloadVersion: payloadVersion
        )

        let metadata = PersonalAccessTokenItem(
            id: UUID(),
            itemID: itemID,
            provider: provider,
            tokenName: tokenName,
            scopesHint: scopesHint
        )
        try database.write { db in
            try PersonalAccessTokenItem.insert {
                metadata
            }
            .execute(db)
        }
        return itemID
    }

    /// Encrypts and stores one field value for a personal-access-token item.
    func addPersonalAccessTokenField(
        itemID: VaultItem.ID,
        fieldName: String,
        plaintext: Data,
        cryptoVersion: Int = 1
    ) throws -> PersonalAccessTokenSecretField.ID {
        _ = try loadPersonalAccessTokenMetadata(itemID: itemID)
        let ciphertext = try sealTypedField(
            itemID: itemID,
            expectedType: .personalAccessToken,
            fieldName: fieldName,
            plaintext: plaintext,
            cryptoVersion: cryptoVersion
        )

        let fieldID = UUID()
        let field = PersonalAccessTokenSecretField(
            id: fieldID,
            itemID: itemID,
            fieldName: fieldName,
            cryptoVersion: cryptoVersion,
            ciphertext: ciphertext
        )
        try database.write { db in
            try PersonalAccessTokenSecretField.insert {
                field
            }
            .execute(db)
        }
        return fieldID
    }

    /// Reveals one personal-access-token field by decrypting with the owning item key.
    func revealPersonalAccessTokenField(fieldID: PersonalAccessTokenSecretField.ID) throws -> Data {
        guard let field = try database.read({ db in
            try PersonalAccessTokenSecretField.where { $0.id.eq(fieldID) }.fetchOne(db)
        }) else {
            throw StoreError.secretFieldNotFound
        }
        return try openTypedField(
            itemID: field.itemID,
            expectedType: .personalAccessToken,
            fieldName: field.fieldName,
            cryptoVersion: field.cryptoVersion,
            ciphertext: field.ciphertext
        )
    }

    /// Creates a database-credential item with typed metadata.
    func createDatabaseCredential(
        vaultID: Vault.ID,
        title: String,
        engine: String,
        host: String,
        port: Int,
        databaseName: String,
        payloadVersion: Int = 1
    ) throws -> VaultItem.ID {
        let itemID = try createItem(
            vaultID: vaultID,
            title: title,
            type: .databaseCredential,
            payloadVersion: payloadVersion
        )

        let metadata = DatabaseCredentialItem(
            id: UUID(),
            itemID: itemID,
            engine: engine,
            host: host,
            port: port,
            databaseName: databaseName
        )
        try database.write { db in
            try DatabaseCredentialItem.insert {
                metadata
            }
            .execute(db)
        }
        return itemID
    }

    /// Encrypts and stores one field value for a database-credential item.
    func addDatabaseCredentialField(
        itemID: VaultItem.ID,
        fieldName: String,
        plaintext: Data,
        cryptoVersion: Int = 1
    ) throws -> DatabaseCredentialSecretField.ID {
        _ = try loadDatabaseCredentialMetadata(itemID: itemID)
        let ciphertext = try sealTypedField(
            itemID: itemID,
            expectedType: .databaseCredential,
            fieldName: fieldName,
            plaintext: plaintext,
            cryptoVersion: cryptoVersion
        )

        let fieldID = UUID()
        let field = DatabaseCredentialSecretField(
            id: fieldID,
            itemID: itemID,
            fieldName: fieldName,
            cryptoVersion: cryptoVersion,
            ciphertext: ciphertext
        )
        try database.write { db in
            try DatabaseCredentialSecretField.insert {
                field
            }
            .execute(db)
        }
        return fieldID
    }

    /// Reveals one database-credential field by decrypting with the owning item key.
    func revealDatabaseCredentialField(fieldID: DatabaseCredentialSecretField.ID) throws -> Data {
        guard let field = try database.read({ db in
            try DatabaseCredentialSecretField.where { $0.id.eq(fieldID) }.fetchOne(db)
        }) else {
            throw StoreError.secretFieldNotFound
        }
        return try openTypedField(
            itemID: field.itemID,
            expectedType: .databaseCredential,
            fieldName: field.fieldName,
            cryptoVersion: field.cryptoVersion,
            ciphertext: field.ciphertext
        )
    }

    /// Creates a mobile release-signing item with typed metadata.
    func createMobileReleaseSigning(
        vaultID: Vault.ID,
        title: String,
        platform: String,
        appIdentifier: String,
        teamOrOrgIdentifier: String,
        payloadVersion: Int = 1
    ) throws -> VaultItem.ID {
        let itemID = try createItem(
            vaultID: vaultID,
            title: title,
            type: .mobileReleaseSigning,
            payloadVersion: payloadVersion
        )

        let metadata = MobileReleaseSigningItem(
            id: UUID(),
            itemID: itemID,
            platform: platform,
            appIdentifier: appIdentifier,
            teamOrOrgIdentifier: teamOrOrgIdentifier
        )
        try database.write { db in
            try MobileReleaseSigningItem.insert {
                metadata
            }
            .execute(db)
        }
        return itemID
    }

    /// Encrypts and stores one field value for a mobile release-signing item.
    func addMobileReleaseSigningField(
        itemID: VaultItem.ID,
        fieldName: String,
        plaintext: Data,
        cryptoVersion: Int = 1
    ) throws -> MobileReleaseSigningSecretField.ID {
        _ = try loadMobileReleaseSigningMetadata(itemID: itemID)
        let ciphertext = try sealTypedField(
            itemID: itemID,
            expectedType: .mobileReleaseSigning,
            fieldName: fieldName,
            plaintext: plaintext,
            cryptoVersion: cryptoVersion
        )

        let fieldID = UUID()
        let field = MobileReleaseSigningSecretField(
            id: fieldID,
            itemID: itemID,
            fieldName: fieldName,
            cryptoVersion: cryptoVersion,
            ciphertext: ciphertext
        )
        try database.write { db in
            try MobileReleaseSigningSecretField.insert {
                field
            }
            .execute(db)
        }
        return fieldID
    }

    /// Reveals one mobile release-signing field by decrypting with the owning item key.
    func revealMobileReleaseSigningField(fieldID: MobileReleaseSigningSecretField.ID) throws -> Data {
        guard let field = try database.read({ db in
            try MobileReleaseSigningSecretField.where { $0.id.eq(fieldID) }.fetchOne(db)
        }) else {
            throw StoreError.secretFieldNotFound
        }
        return try openTypedField(
            itemID: field.itemID,
            expectedType: .mobileReleaseSigning,
            fieldName: field.fieldName,
            cryptoVersion: field.cryptoVersion,
            ciphertext: field.ciphertext
        )
    }

    private func sealTypedField(
        itemID: VaultItem.ID,
        expectedType: VaultItemType,
        fieldName: String,
        plaintext: Data,
        cryptoVersion: Int
    ) throws -> Data {
        let (item, itemType, itemKey) = try loadItemAndKey(itemID: itemID)
        guard itemType == expectedType else {
            throw StoreError.unsupportedItemType
        }
        return try EnvelopeCrypto.seal(
            plaintext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: item.id,
                itemType: itemType,
                fieldName: fieldName,
                cryptoVersion: cryptoVersion
            )
        )
    }

    private func openTypedField(
        itemID: VaultItem.ID,
        expectedType: VaultItemType,
        fieldName: String,
        cryptoVersion: Int,
        ciphertext: Data
    ) throws -> Data {
        let (_, itemType, itemKey) = try loadItemAndKey(itemID: itemID)
        guard itemType == expectedType else {
            throw StoreError.unsupportedItemType
        }
        return try EnvelopeCrypto.open(
            ciphertext,
            using: itemKey,
            aad: EnvelopeAAD.itemField(
                itemID: itemID,
                itemType: itemType,
                fieldName: fieldName,
                cryptoVersion: cryptoVersion
            )
        )
    }

    private func loadSoftwareLicenseMetadata(itemID: VaultItem.ID) throws -> SoftwareLicenseItem {
        guard let metadata = try database.read({ db in
            try SoftwareLicenseItem.where { $0.itemID.eq(itemID) }.fetchOne(db)
        }) else {
            throw StoreError.typedItemMetadataNotFound
        }
        return metadata
    }

    private func loadUsernamePasswordMetadata(itemID: VaultItem.ID) throws -> UsernamePasswordItem {
        guard let metadata = try database.read({ db in
            try UsernamePasswordItem.where { $0.itemID.eq(itemID) }.fetchOne(db)
        }) else {
            throw StoreError.typedItemMetadataNotFound
        }
        return metadata
    }

    private func loadPersonalAccessTokenMetadata(itemID: VaultItem.ID) throws -> PersonalAccessTokenItem {
        guard let metadata = try database.read({ db in
            try PersonalAccessTokenItem.where { $0.itemID.eq(itemID) }.fetchOne(db)
        }) else {
            throw StoreError.typedItemMetadataNotFound
        }
        return metadata
    }

    private func loadDatabaseCredentialMetadata(itemID: VaultItem.ID) throws -> DatabaseCredentialItem {
        guard let metadata = try database.read({ db in
            try DatabaseCredentialItem.where { $0.itemID.eq(itemID) }.fetchOne(db)
        }) else {
            throw StoreError.typedItemMetadataNotFound
        }
        return metadata
    }

    private func loadMobileReleaseSigningMetadata(itemID: VaultItem.ID) throws -> MobileReleaseSigningItem {
        guard let metadata = try database.read({ db in
            try MobileReleaseSigningItem.where { $0.itemID.eq(itemID) }.fetchOne(db)
        }) else {
            throw StoreError.typedItemMetadataNotFound
        }
        return metadata
    }
}
