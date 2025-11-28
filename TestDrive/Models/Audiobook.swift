import Foundation

/// Represents an audiobook with associated metadata.
struct Audiobook: Identifiable, Comparable, Hashable {
    /// The unique identifier for the audiobook.
    let id: String

    /// The number of highlights saved for this audiobook.
    let highlightCount: Int

    /// The last time this audiobook was accessed.
    let lastAccessed: Date

    // MARK: - Comparable

    /// Compares two audiobooks by last accessed date (most recent first).
    static func < (lhs: Audiobook, rhs: Audiobook) -> Bool {
        lhs.lastAccessed > rhs.lastAccessed
    }
}
