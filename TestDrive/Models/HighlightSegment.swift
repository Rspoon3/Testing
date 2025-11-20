import Foundation
import SQLiteData

/// Maps a highlight to specific transcript segments with character offsets.
@Table
struct HighlightSegment {
    /// Unique identifier for this segment mapping.
    let id: UUID

    /// The highlight this segment belongs to.
    var highlightId: UUID = UUID()

    /// The ID of the transcript segment (from the transcript database).
    var segmentId: Int = 0

    /// Character offset where the highlight starts in this segment (0 = beginning).
    var startCharOffset: Int = 0

    /// Character offset where the highlight ends in this segment (length = end).
    var endCharOffset: Int = 0
}
