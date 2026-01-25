import CloudKit
import Foundation
import GRDB
import SQLiteData
import TestDriveCore

/// Manages the SQLite database with CloudKit synchronization.
///
/// This manager configures and maintains the SQLiteData database connection,
/// sets up CloudKit sync for end-to-end encrypted vault sharing, and provides
/// a clean interface for database operations.
@MainActor
@Observable
public final class DatabaseManager {

    private let database: DatabaseQueue
    private var syncEngine: SyncEngine?

    public var isSyncing = false
    public var lastSyncDate: Date?
    public var syncError: Error?

    // MARK: - Initializer

    /// Creates a new database manager.
    ///
    /// - Parameters:
    ///   - containerIdentifier: CloudKit container identifier.
    ///   - enableSync: Whether to enable CloudKit sync.
    /// - Throws: Database error if initialization fails.
    public init(
        containerIdentifier: String = "iCloud.com.rspoon3.TestDrive",
        enableSync: Bool = true
    ) throws {
        let fileURL = try Self.databaseURL()

        // Use SQLiteData's defaultDatabase to enable @FetchAll observation
        var configuration = GRDB.Configuration()
        configuration.prepareDatabase { db in
            try db.attachMetadatabase()
        }
        self.database = try SQLiteData.defaultDatabase(at: fileURL.path, configuration: configuration)
        self.syncEngine = nil

        // Create database schema BEFORE initializing SyncEngine
        try initializeDatabase()

        if enableSync {
            self.syncEngine = try SyncEngine(
                for: database,
                tables: APIKey.self, Vault.self, VaultParticipant.self, WrappedVaultKey.self,
                containerIdentifier: containerIdentifier
            )
        }
    }

    // MARK: - Database Operations

    /// Reads from the database.
    ///
    /// - Parameter query: A closure that performs read operations.
    /// - Returns: The result of the query.
    /// - Throws: Database error if the query fails.
    public func read<T: Sendable>(
        _ query: @escaping @Sendable (GRDB.Database) throws -> T
    ) async throws -> T {
        try await database.read(query)
    }

    /// Writes to the database.
    ///
    /// - Parameter update: A closure that performs write operations.
    /// - Throws: Database error if the update fails.
    public func write(
        _ update: @escaping @Sendable (GRDB.Database) throws -> Void
    ) async throws {
        try await database.write(update)
    }

    // MARK: - Sync Operations

    /// Starts the sync engine for automatic background sync.
    public func startSync() async throws {
        guard let syncEngine else { return }
        try await syncEngine.start()
    }

    /// Stops the sync engine.
    public func stopSync() {
        guard let syncEngine else { return }
        syncEngine.stop()
    }

    // MARK: - Private Helpers

    /// Initializes the database schema.
    ///
    /// Creates all necessary tables before SyncEngine initialization.
    private func initializeDatabase() throws {
        var migrator = DatabaseMigrator()

        // Migration v1: Create initial schema
        migrator.registerMigration("v1") { db in
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
    }

    /// Observes sync state changes.
    @MainActor
    private func startObservingSyncState() async {
        // Monitor sync state through SQLiteData's sync engine
        // This is a placeholder for the actual implementation
        // In production, you'd observe sync engine notifications
    }

    /// Returns the URL for the database file.
    ///
    /// - Returns: The URL in the app's Application Support directory.
    /// - Throws: FileManager error if the directory cannot be created.
    private static func databaseURL() throws -> URL {
        let fileManager = FileManager.default

        let supportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return supportURL.appendingPathComponent("apikeys.sqlite")
    }
}
