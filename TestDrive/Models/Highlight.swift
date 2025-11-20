import Foundation
import SQLiteData

/// Represents a user's highlight on an audiobook transcript.
@Table
struct Highlight {
    /// Unique identifier for the highlight.
    let id: UUID

    /// The audiobook this highlight belongs to.
    var audiobookId: String = ""

    /// The timestamp in the audiobook where this highlight occurs (in seconds).
    var timestamp: Double = 0.0

    /// The full text that was highlighted across all segments.
    var highlightedText: String = ""

    /// Optional user comment or note about this highlight.
    var comment: String? = nil

    /// When this highlight was created.
    var createdAt: Date = Date()

    /// When this highlight was last modified.
    var modifiedAt: Date = Date()
}
