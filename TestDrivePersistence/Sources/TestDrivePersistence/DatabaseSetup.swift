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

    var configuration = Configuration()
    configuration.foreignKeysEnabled = true
    configuration.prepareDatabase { db in
        try db.attachMetadatabase()

        // Create temporary view combining Vault with VaultPreference and key count
        try VaultRow.createTemporaryView(
            as: Vault
                .order(by: \.createdAt)
                .leftJoin(VaultPreference.all) { $0.id.eq($1.vaultID) }
                .leftJoin(Credential.all) { $0.id.eq($2.vaultID) }
                .group { vault, _, _ in vault.id }
                .select {
                    VaultRow.Columns(
                        vault: $0,
                        isPinned: $1.isPinned ?? false,
                        keyCount: $2.count()
                    )
                }
        )
        .execute(db)

        // Create temporary view combining Credential with CredentialPreference
        try CredentialRow.createTemporaryView(
            as: Credential
                .order(by: \.createdAt)
                .leftJoin(CredentialPreference.all) { $0.id.eq($1.credentialID) }
                .select {
                    CredentialRow.Columns(
                        credential: $0,
                        isPinned: $1.isPinned ?? false
                    )
                }
        )
        .execute(db)
    }

    // Use document directory for persistent storage
    let path = URL.documentsDirectory.appending(component: "testdrive.sqlite").path()
    database = try DatabasePool(path: path, configuration: configuration)

    // Run migrations
    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1 - Create tables and FTS5") { db in
        // Create vaults table
        try db.create(table: "vaults") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("name", .text).notNull()
            t.column("iconName", .text).notNull()
            t.column("colorHex", .text).notNull()
            t.column("sortOrder", .integer).notNull()
            t.column("isDefault", .boolean).notNull()
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
            t.column("ownerPublicKey", .blob).notNull()
            t.column("ckRecordID", .text)
            t.column("ckShareID", .text)
            t.column("isShared", .boolean).notNull()
            t.column("ownerUserID", .text)
        }

        // Create credentials table (metadata only, secrets in separate table)
        try db.create(table: "credentials") { t in
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
            t.column("ckRecordID", .text)

            t.foreignKey(["vaultID"], references: "vaults", columns: ["id"], onDelete: .cascade)
        }

        // Create credentialSecrets table (one-to-many with credentials)
        try db.create(table: "credentialSecrets") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("credentialID", .blob).notNull()
            t.column("secretLabel", .text).notNull()
            t.column("encryptedSecret", .blob).notNull()
            t.column("nonce", .blob).notNull()
            t.column("sortOrder", .integer).notNull().defaults(to: 0)
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
            t.column("lastUsedAt", .datetime)
            t.column("copyCount", .integer).notNull().defaults(to: 0)
            t.column("expiresAt", .datetime)
            t.column("rotateAt", .datetime)
            t.column("status", .text).notNull().defaults(to: "active")
            t.column("ckRecordID", .text)

            t.foreignKey(["credentialID"], references: "credentials", columns: ["id"], onDelete: .cascade)
            t.uniqueKey(["credentialID", "secretLabel"]) // No duplicate labels per credential
        }

        // Create indexes for credentialSecrets
        try db.create(index: "idx_credentialSecrets_credentialID", on: "credentialSecrets", columns: ["credentialID"])
        try db.create(index: "idx_credentialSecrets_sortOrder", on: "credentialSecrets", columns: ["credentialID", "sortOrder"])
        try db.create(index: "idx_credentialSecrets_status", on: "credentialSecrets", columns: ["status"])

        // Create credentialSecretHistories table (audit log) - pluralized to match @Table macro
        try db.create(table: "credentialSecretHistories") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("credentialSecretID", .blob).notNull()
            t.column("encryptedSecret", .blob).notNull()
            t.column("nonce", .blob).notNull()
            t.column("replacedAt", .datetime).notNull()
            t.column("reason", .text).notNull()
            t.column("copyCount", .integer).notNull().defaults(to: 0)

            t.foreignKey(["credentialSecretID"], references: "credentialSecrets", columns: ["id"], onDelete: .cascade)
        }

        // Create index for secret history
        try db.create(index: "idx_secretHistory_secretID", on: "credentialSecretHistories", columns: ["credentialSecretID"])

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

        // Create vaultPreferences table (local only, not synced to CloudKit)
        try db.create(table: "vaultPreferences") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("vaultID", .blob).notNull()
            t.column("isPinned", .boolean).notNull().defaults(to: false)

            t.foreignKey(["vaultID"], references: "vaults", columns: ["id"], onDelete: .cascade)
            t.uniqueKey(["vaultID"]) // One preferences record per vault
        }

        // Create credentialPreferences table (local only, not synced to CloudKit)
        try db.create(table: "credentialPreferences") { t in
            t.column("id", .blob).notNull().primaryKey()
            t.column("credentialID", .blob).notNull()
            t.column("isPinned", .boolean).notNull().defaults(to: false)

            t.foreignKey(["credentialID"], references: "credentials", columns: ["id"], onDelete: .cascade)
            t.uniqueKey(["credentialID"]) // One preferences record per credential
        }

        // Create FTS5 virtual table for full-text search
        // Using porter tokenizer for better prefix matching (allows "Gi" to match "GitHub")
        try #sql(
            """
            CREATE VIRTUAL TABLE "credentialTexts" USING fts5(
              "label",
              "websiteDomain",
              "company",
              "notes",
              tokenize='porter unicode61'
            )
            """
        )
        .execute(db)
    }

    try migrator.migrate(database)

    // Set up triggers to keep FTS5 in sync with Credential table
    try database.write { db in
        // Insert trigger: Add row to FTS5 when Credential is inserted
        try Credential.createTemporaryTrigger(
            after: .insert { new in
                CredentialText.insert {
                    CredentialText.Columns(
                        rowid: new.rowid,
                        label: new.label,
                        websiteDomain: new.websiteDomain ?? "",
                        company: new.company ?? "",
                        notes: new.notes
                    )
                }
            }
        )
        .execute(db)

        // Update trigger: Update FTS5 when searchable columns change
        try Credential.createTemporaryTrigger(
            after: .update {
                ($0.label, $0.websiteDomain, $0.company, $0.notes)
            } forEachRow: { _, new in
                CredentialText
                    .where { $0.rowid.eq(new.rowid) }
                    .update {
                        $0.label = new.label
                        $0.websiteDomain = new.websiteDomain ?? ""
                        $0.company = new.company ?? ""
                        $0.notes = new.notes
                    }
            }
        )
        .execute(db)

        // Delete trigger: Remove from FTS5 when Credential is deleted
        try Credential.createTemporaryTrigger(
            after: .delete { old in
                CredentialText
                    .where { $0.rowid.eq(old.rowid) }
                    .delete()
            }
        )
        .execute(db)

        // Configure BM25 ranking with weighted columns
        try #sql(
            """
            INSERT INTO \(CredentialText.self)
            (\(CredentialText.self), rank)
            VALUES
            ('rank', 'bm25(10, 5, 5, 1)')
            """
        )
        .execute(db)
    }

    return database
}
