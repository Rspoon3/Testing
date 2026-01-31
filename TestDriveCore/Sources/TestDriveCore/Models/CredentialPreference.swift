import Foundation
import SQLiteData

/// Local-only user preferences for an credential.
///
/// This table is not synced to CloudKit, allowing each user to maintain
/// their own preferences (like pin status) without affecting other users
/// or syncing across devices.
@Table
public struct CredentialPreference: Identifiable, Sendable, Equatable {
    /// Unique identifier for the preferences record.
    public let id: UUID

    /// The credential these preferences apply to.
    public var credentialID: UUID

    /// Indicates if this credential is pinned to the top of the list.
    public var isPinned: Bool

    // MARK: - Initializer

    /// Creates new credential preferences.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - credentialID: The credential these preferences apply to.
    ///   - isPinned: Whether the credential is pinned.
    public init(
        id: UUID = UUID(),
        credentialID: UUID,
        isPinned: Bool = false
    ) {
        self.id = id
        self.credentialID = credentialID
        self.isPinned = isPinned
    }
}
