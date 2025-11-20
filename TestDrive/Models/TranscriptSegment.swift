import Foundation
import GRDB

/// Represents a segment of an audiobook transcript with timing information.
/// This model is used to read from downloaded transcript databases.
struct TranscriptSegment: Codable, FetchableRecord {
    /// Unique identifier for the segment.
    let id: Int

    /// The audiobook this segment belongs to.
    let audiobookId: String?

    /// Start time of this segment in milliseconds.
    let start: Int

    /// End time of this segment in milliseconds.
    let end: Int

    /// The transcript text for this segment.
    let text: String

    // MARK: - Database Column Mapping

    enum CodingKeys: String, CodingKey {
        case id
        case audiobookId = "audiobook_id"
        case start
        case end
        case text
    }

    // MARK: - Public Helpers

    /// Start time in seconds.
    var startTimeInSeconds: Double {
        Double(start) / 1000.0
    }

    /// End time in seconds.
    var endTimeInSeconds: Double {
        Double(end) / 1000.0
    }
}
