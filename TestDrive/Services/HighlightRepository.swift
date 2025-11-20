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
            print("🔍 Fetching highlights for audiobookId: \(audiobookId)")

            let results = try Highlight
                .where { $0.audiobookId.eq(audiobookId) }
                .order { $0.timestamp.asc() }
                .fetchAll(db)

            print("🔍 Found \(results.count) highlights")
            return results
        }
    }

    /// Deletes a highlight and its associated segment mappings.
    /// - Parameter highlightId: The highlight ID to delete.
    /// - Throws: Database errors.
    func deleteHighlight(_ highlightId: UUID) throws {
        try database.write { db in
            try Highlight
                .where { $0.id.eq(highlightId) }
                .delete()
                .execute(db)
        }
    }

    /// Updates the comment for a highlight.
    /// - Parameters:
    ///   - highlightId: The highlight ID.
    ///   - comment: The new comment text.
    /// - Throws: Database errors.
    func updateComment(_ highlightId: UUID, comment: String?) throws {
        try database.write { db in
            try Highlight
                .where { $0.id.eq(highlightId) }
                .update {
                    $0.comment = comment
                    $0.modifiedAt = Date()
                }
                .execute(db)
        }
    }
}
