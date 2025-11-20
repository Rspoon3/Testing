import Foundation
import GRDB

/// Provides access to transcript segments from downloaded transcript databases.
struct TranscriptRepository {
    // MARK: - Public Helpers

    /// Checks if a transcript database exists for the given audiobook.
    /// - Parameter audiobookId: The audiobook identifier.
    /// - Returns: True if the transcript file exists, false otherwise.
    func transcriptExists(audiobookId: String) -> Bool {
        guard let url = transcriptURL(for: audiobookId) else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Fetches transcript segments at a specific timestamp with surrounding context.
    /// - Parameters:
    ///   - timestamp: The timestamp in seconds.
    ///   - audiobookId: The audiobook identifier.
    ///   - contextWindow: Number of seconds before and after to include (default: 30).
    /// - Returns: Array of transcript segments within the context window.
    /// - Throws: Database query errors.
    func segmentsAtTimestamp(
        _ timestamp: Double,
        audiobookId: String,
        contextWindow: TimeInterval = 30
    ) throws -> [TranscriptSegment] {
        guard let url = transcriptURL(for: audiobookId) else {
            throw TranscriptRepositoryError.transcriptNotFound
        }

        let dbQueue = try DatabaseQueue(path: url.path)

        return try dbQueue.read { db in
            // Convert seconds to milliseconds
            let startTimeMs = Int((timestamp - contextWindow) * 1000)
            let endTimeMs = Int((timestamp + contextWindow) * 1000)

            let sql = """
                SELECT * FROM transcript_segment
                WHERE start <= ? AND end >= ?
                ORDER BY start
                """

            let segments = try TranscriptSegment.fetchAll(
                db,
                sql: sql,
                arguments: [endTimeMs, startTimeMs]
            )

            return segments
        }
    }

    /// Fetches all transcript segments for an audiobook.
    /// - Parameter audiobookId: The audiobook identifier.
    /// - Returns: Array of all transcript segments, ordered by start time.
    /// - Throws: Database query errors.
    func allSegments(audiobookId: String) throws -> [TranscriptSegment] {
        guard let url = transcriptURL(for: audiobookId) else {
            throw TranscriptRepositoryError.transcriptNotFound
        }

        let dbQueue = try DatabaseQueue(path: url.path)

        return try dbQueue.read { db in
            let sql = """
                SELECT * FROM transcript_segment
                ORDER BY start
                """

            return try TranscriptSegment.fetchAll(db, sql: sql)
        }
    }

    /// Fetches the transcript segment that contains a specific timestamp.
    /// - Parameters:
    ///   - timestamp: The timestamp in seconds.
    ///   - audiobookId: The audiobook identifier.
    /// - Returns: The segment containing the timestamp, or nil if not found.
    /// - Throws: Database query errors.
    func segmentAtTimestamp(
        _ timestamp: Double,
        audiobookId: String
    ) throws -> TranscriptSegment? {
        guard let url = transcriptURL(for: audiobookId) else {
            throw TranscriptRepositoryError.transcriptNotFound
        }

        let dbQueue = try DatabaseQueue(path: url.path)

        return try dbQueue.read { db in
            // Convert seconds to milliseconds
            let timestampMs = Int(timestamp * 1000)

            let sql = """
                SELECT * FROM transcript_segment
                WHERE start <= ? AND end >= ?
                LIMIT 1
                """

            return try TranscriptSegment.fetchOne(
                db,
                sql: sql,
                arguments: [timestampMs, timestampMs]
            )
        }
    }

    // MARK: - Private Helpers

    /// Gets the file URL for a transcript database.
    /// - Parameter audiobookId: The audiobook identifier.
    /// - Returns: The URL to the transcript database file, or nil if not found.
    private func transcriptURL(for audiobookId: String) -> URL? {
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else {
            return nil
        }

        let url = appSupport
            .appendingPathComponent("transcripts")
            .appendingPathComponent("\(audiobookId).db")

        return url
    }
}

// MARK: - Error Types

enum TranscriptRepositoryError: LocalizedError {
    case transcriptNotFound

    var errorDescription: String? {
        switch self {
        case .transcriptNotFound:
            return "Transcript database not found. Please download it first."
        }
    }
}
