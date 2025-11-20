import Foundation
import GRDB
import Dependencies
import SQLiteData

/// Repository for managing highlights in the database.
struct HighlightRepository {
    @Dependency(\.defaultDatabase) var database

    // MARK: - Public Helpers

    /// Saves a new highlight with its segment mappings.
    /// - Parameters:
    ///   - audiobookId: The audiobook identifier.
    ///   - timestamp: The timestamp in seconds where the highlight occurs.
    ///   - highlightedText: The selected text.
    ///   - comment: Optional user comment.
    ///   - segments: Array of affected segments with offsets.
    /// - Returns: The created highlight with its ID.
    /// - Throws: Database errors.
    func saveHighlight(
        audiobookId: String,
        timestamp: Double,
        highlightedText: String,
        comment: String?,
        segments: [(segment: TranscriptSegment, startOffset: Int, endOffset: Int)]
    ) throws -> Highlight {
        print("🗄️ Saving to database...")

        let result = try database.write { db in
            let now = Date()
            let highlight = Highlight(
                id: UUID(),
                audiobookId: audiobookId,
                timestamp: timestamp,
                highlightedText: highlightedText,
                comment: comment,
                createdAt: now,
                modifiedAt: now
            )

            print("  Inserting highlight...")
            try Highlight.insert { highlight }.execute(db)
            print("  ✅ Highlight inserted")

            // Create segment mappings
            print("  Inserting \(segments.count) segment mappings...")
            for (index, item) in segments.enumerated() {
                let highlightSegment = HighlightSegment(
                    id: UUID(),
                    highlightId: highlight.id,
                    segmentId: item.segment.id,
                    startCharOffset: item.startOffset,
                    endCharOffset: item.endOffset
                )
                try HighlightSegment.insert { highlightSegment }.execute(db)
                print("    ✅ Segment \(index + 1)/\(segments.count) inserted")
            }

            return highlight
        }

        print("🗄️ Database save complete!")
        return result
    }

    /// Fetches all highlights for a specific audiobook.
    /// - Parameter audiobookId: The audiobook identifier.
    /// - Returns: Array of highlights ordered by timestamp.
    /// - Throws: Database errors.
    func highlights(for audiobookId: String) throws -> [Highlight] {
        try database.read { db in
            let sql = """
                SELECT id, audiobookId, timestamp, highlightedText, comment, createdAt, modifiedAt
                FROM highlights
                WHERE audiobookId = ?
                ORDER BY timestamp
                """

            print("🔍 Fetching highlights for audiobookId: \(audiobookId)")
            let rows = try Row.fetchAll(db, sql: sql, arguments: [audiobookId])
            print("🔍 Found \(rows.count) rows")

            let results = rows.compactMap { row -> Highlight? in
                do {
                    // Use GRDB's Row subscript to get the actual values
                    let idString: String = try row["id"]
                    let audiobookId: String = try row["audiobookId"]
                    let timestamp: Double = try row["timestamp"]
                    let highlightedText: String = try row["highlightedText"]

                    // SQLiteData stores dates as ISO8601 strings
                    let createdAtString: String = try row["createdAt"]
                    let modifiedAtString: String = try row["modifiedAt"]
                    let comment: String? = try? row["comment"]

                    // Parse UUID from string
                    guard let id = UUID(uuidString: idString) else {
                        print("❌ Failed to parse UUID from: \(idString)")
                        return nil
                    }

                    // Parse date strings (format: "2025-11-20 20:12:16.690")
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                    dateFormatter.timeZone = TimeZone.current

                    guard let createdAt = dateFormatter.date(from: createdAtString) else {
                        print("❌ Failed to parse createdAt: \(createdAtString)")
                        return nil
                    }

                    guard let modifiedAt = dateFormatter.date(from: modifiedAtString) else {
                        print("❌ Failed to parse modifiedAt: \(modifiedAtString)")
                        return nil
                    }

                    let highlight = Highlight(
                        id: id,
                        audiobookId: audiobookId,
                        timestamp: timestamp,
                        highlightedText: highlightedText,
                        comment: comment,
                        createdAt: createdAt,
                        modifiedAt: modifiedAt
                    )

                    print("✅ Parsed highlight: \(highlight.id)")
                    return highlight
                } catch {
                    print("❌ Failed to parse row: \(error)")
                    return nil
                }
            }

            print("🔍 Returning \(results.count) highlights")
            return results
        }
    }

    /// Deletes a highlight and its associated segment mappings.
    /// - Parameter highlightId: The highlight ID to delete.
    /// - Throws: Database errors.
    func deleteHighlight(_ highlightId: UUID) throws {
        try database.write { db in
            try db.execute(
                sql: "DELETE FROM highlights WHERE id = ?",
                arguments: [highlightId]
            )
        }
    }

    /// Updates the comment for a highlight.
    /// - Parameters:
    ///   - highlightId: The highlight ID.
    ///   - comment: The new comment text.
    /// - Throws: Database errors.
    func updateComment(_ highlightId: UUID, comment: String?) throws {
        try database.write { db in
            try db.execute(
                sql: "UPDATE highlights SET comment = ?, modifiedAt = ? WHERE id = ?",
                arguments: [comment, Date(), highlightId]
            )
        }
    }
}
