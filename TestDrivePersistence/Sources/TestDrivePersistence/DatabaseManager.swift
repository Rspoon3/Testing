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
@Observable
public final class DatabaseManager {

    private let database: DatabaseQueue
    private let syncEngine: SyncEngine?

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

        self.database = try DatabaseQueue(path: fileURL.path)

        if enableSync {
            self.syncEngine = try SyncEngine(
                for: database,
                tables: APIKey.self, Vault.self, VaultParticipant.self, WrappedVaultKey.self,
                containerIdentifier: containerIdentifier
            )

            // Start observing sync state
            Task { @MainActor in
                await startObservingSyncState()
            }
        } else {
            self.syncEngine = nil
        }

        try initializeDatabase()
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
    /// SQLiteData's @Table macro handles schema creation automatically.
    /// This method is here for any additional setup needed.
    private func initializeDatabase() throws {
        // SQLiteData @Table macro creates tables automatically
        // Additional indexes or constraints can be added here if needed
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
