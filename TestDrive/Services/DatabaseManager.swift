import Foundation
import GRDB
import SQLiteData

/// Manages the highlights database for storing user annotations.
struct DatabaseManager {
    // MARK: - Public Helpers

    /// Creates and configures the highlights database.
    /// - Returns: A configured DatabaseQueue for the highlights database.
    /// - Throws: Database initialization errors.
    static func createHighlightsDatabase() throws -> DatabaseQueue {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let dbPath = appSupport.appendingPathComponent("highlights.db").path

        let dbQueue = try DatabaseQueue(path: dbPath)

        // Run migrations to create tables
        try dbQueue.write { db in
            try createTables(db)
        }

        return dbQueue
    }

    // MARK: - Private Helpers

    /// Creates the necessary tables for highlights storage.
    /// - Parameter db: The database connection.
    /// - Throws: Database schema creation errors.
    private static func createTables(_ db: Database) throws {
        // Create highlight table
        try db.create(table: "Highlight", ifNotExists: true) { t in
            t.primaryKey("id", .blob)
            t.column("audiobookId", .text).notNull()
            t.column("timestamp", .real).notNull()
            t.column("highlightedText", .text).notNull()
            t.column("comment", .text)
            t.column("createdAt", .real).notNull()
            t.column("modifiedAt", .real).notNull()
        }

        // Create highlight_segment table
        try db.create(table: "HighlightSegment", ifNotExists: true) { t in
            t.primaryKey("id", .blob)
            t.column("highlightId", .blob).notNull()
            t.column("segmentId", .integer).notNull()
            t.column("startCharOffset", .integer).notNull()
            t.column("endCharOffset", .integer).notNull()

            t.foreignKey(
                ["highlightId"],
                references: "Highlight",
                columns: ["id"],
                onDelete: .cascade
            )
        }

        // Create indexes for common queries
        try db.create(
            index: "idx_highlight_audiobook",
            on: "Highlight",
            columns: ["audiobookId", "timestamp"],
            ifNotExists: true
        )

        try db.create(
            index: "idx_highlight_segment_highlight",
            on: "HighlightSegment",
            columns: ["highlightId"],
            ifNotExists: true
        )
    }
}
