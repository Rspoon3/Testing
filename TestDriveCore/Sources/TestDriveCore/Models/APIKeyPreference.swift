import Foundation
import SQLiteData

/// Local-only user preferences for an API key.
///
/// This table is not synced to CloudKit, allowing each user to maintain
/// their own preferences (like pin status) without affecting other users
/// or syncing across devices.
@Table
public struct APIKeyPreference: Identifiable, Sendable, Equatable {
    /// Unique identifier for the preferences record.
    public let id: UUID

    /// The API key these preferences apply to.
    public var apiKeyID: UUID

    /// Indicates if this API key is pinned to the top of the list.
    public var isPinned: Bool

    // MARK: - Initializer

    /// Creates new API key preferences.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - apiKeyID: The API key these preferences apply to.
    ///   - isPinned: Whether the API key is pinned.
    public init(
        id: UUID = UUID(),
        apiKeyID: UUID,
        isPinned: Bool = false
    ) {
        self.id = id
        self.apiKeyID = apiKeyID
        self.isPinned = isPinned
    }
}
