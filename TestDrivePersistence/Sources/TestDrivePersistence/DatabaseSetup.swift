import Foundation
import GRDB
import SQLiteData
import TestDriveCore

/// Creates and configures the app's database.
///
/// This function creates the database connection with proper configuration,
/// runs migrations, and returns the database writer for use with @FetchAll.
///
/// - Returns: The configured database writer.
/// - Throws: Database error if initialization fails.
public func appDatabase() throws -> any DatabaseWriter {
    let database: any DatabaseWriter

    var configuration = GRDB.Configuration()
    configuration.foreignKeysEnabled = true
    configuration.prepareDatabase { db in
        try db.attachMetadatabase()
    }

    // Use document directory for persistent storage
    let path = URL.documentsDirectory.appending(component: "testdrive.sqlite").path()
    database = try DatabasePool(path: path, configuration: configuration)

    // Run migrations
    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1") { db in
        // Create vaults table
        try db.create(table: "vaults") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("name", .text).notNull()
            t.column("iconName", .text).notNull()
            t.column("colorHex", .text).notNull()
            t.column("sortOrder", .integer).notNull()
            t.column("isPinned", .boolean).notNull().defaults(to: false)
            t.column("isDefault", .boolean).notNull()
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
            t.column("ownerPublicKey", .blob).notNull()
            t.column("ckRecordID", .text)
            t.column("ckShareID", .text)
            t.column("isShared", .boolean).notNull()
            t.column("ownerUserID", .text)
        }

        // Create apiKeys table
        try db.create(table: "apiKeys") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("label", .text).notNull()
            t.column("websiteDomain", .text)
            t.column("company", .text)
            t.column("environment", .text).notNull()
            t.column("tagsString", .text).notNull()
            t.column("createdAt", .datetime).notNull()
            t.column("rotateAt", .datetime)
            t.column("lastUsedAt", .datetime)
            t.column("notes", .text).notNull()
            t.column("vaultID", .blob).notNull()
            t.column("encryptedSecret", .blob).notNull()
            t.column("nonce", .blob).notNull()
            t.column("ckRecordID", .text)

            t.foreignKey(["vaultID"], references: "vaults", columns: ["id"], onDelete: .cascade)
        }

        // Create vaultParticipants table
        try db.create(table: "vaultParticipants") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("vaultID", .blob).notNull()
            t.column("userID", .text).notNull()
            t.column("publicKey", .blob)
            t.column("permission", .text).notNull()
            t.column("acceptanceStatus", .text).notNull()
            t.column("addedAt", .datetime).notNull()

            t.foreignKey(["vaultID"], references: "vaults", columns: ["id"], onDelete: .cascade)
        }

        // Create wrappedVaultKeys table
        try db.create(table: "wrappedVaultKeys") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("vaultID", .blob).notNull()
            t.column("recipientUserID", .text).notNull()
            t.column("encryptedVaultKey", .blob).notNull()
            t.column("ephemeralPublicKey", .blob).notNull()
            t.column("wrappedAt", .datetime).notNull()
            t.column("ckRecordID", .text)

            t.foreignKey(["vaultID"], references: "vaults", columns: ["id"], onDelete: .cascade)
        }
    }

    try migrator.migrate(database)

    return database
}
