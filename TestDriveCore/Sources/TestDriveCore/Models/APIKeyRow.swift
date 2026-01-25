import Foundation
import SQLiteData

/// A row combining an API key with its local preferences.
///
/// Used for efficiently fetching API keys with their pin state in a single query.
@Selection
public struct APIKeyRow: Sendable, Equatable {
    /// The API key.
    public let apiKey: APIKey

    /// The local preferences for this API key (nil if none exist).
    public let preference: APIKeyPreference?

    /// Whether this API key is pinned.
    public var isPinned: Bool {
        preference?.isPinned ?? false
    }

    // MARK: - Initializer

    /// Creates a new API key row.
    ///
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - preference: The local preferences for this API key.
    public init(apiKey: APIKey, preference: APIKeyPreference? = nil) {
        self.apiKey = apiKey
        self.preference = preference
    }
}
