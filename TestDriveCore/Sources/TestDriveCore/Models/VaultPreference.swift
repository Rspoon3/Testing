import Foundation
import SQLiteData

/// Local-only user preferences for a vault.
///
/// This table is not synced to CloudKit, allowing each user to maintain
/// their own preferences (like pin status) without affecting other users
/// or syncing across devices.
@Table
public struct VaultPreference: Identifiable, Sendable, Equatable {
    /// Unique identifier for the preferences record.
    public let id: UUID

    /// The vault these preferences apply to.
    public var vaultID: UUID

    /// Indicates if this vault is pinned to the top of the list.
    public var isPinned: Bool

    // MARK: - Initializer

    /// Creates new vault preferences.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - vaultID: The vault these preferences apply to.
    ///   - isPinned: Whether the vault is pinned.
    public init(
        id: UUID = UUID(),
        vaultID: UUID,
        isPinned: Bool = false
    ) {
        self.id = id
        self.vaultID = vaultID
        self.isPinned = isPinned
    }
}
