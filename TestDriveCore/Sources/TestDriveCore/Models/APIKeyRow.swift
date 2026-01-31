import Foundation
import SQLiteData

/// A row combining an API key with its local preferences.
///
/// Used for efficiently fetching API keys with their pin state in a single query.
@Selection
public struct APIKeyRow: Sendable, Equatable {
    /// The API key.
    public let apiKey: APIKey

    /// Whether this API key is pinned.
    public let isPinned: Bool

    // MARK: - Initializer

    /// Creates a new API key row.
    ///
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - isPinned: Whether the API key is pinned.
    public init(apiKey: APIKey, isPinned: Bool) {
        self.apiKey = apiKey
        self.isPinned = isPinned
    }
}
