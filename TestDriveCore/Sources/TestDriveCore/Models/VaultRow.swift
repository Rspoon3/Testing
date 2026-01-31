import Foundation
import SQLiteData

/// Row type combining vault with its local-only preferences and key count.
///
/// This selection is created as a temporary view that joins Vault with VaultPreference
/// and counts associated credentials, allowing efficient querying of vaults with their
/// pin status and key counts.
@Selection
public struct VaultRow: Equatable, Sendable, Identifiable, Hashable {
    /// Unique identifier (uses vault's id).
    public var id: UUID { vault.id }
    /// The vault.
    public let vault: Vault

    /// Whether this vault is pinned to the top of the list.
    public let isPinned: Bool

    /// The number of credentials in this vault.
    public let keyCount: Int

    // MARK: - Initializer

    /// Creates a new vault row.
    ///
    /// - Parameters:
    ///   - vault: The vault.
    ///   - isPinned: Whether the vault is pinned.
    ///   - keyCount: The number of credentials in the vault.
    public init(vault: Vault, isPinned: Bool, keyCount: Int = 0) {
        self.vault = vault
        self.isPinned = isPinned
        self.keyCount = keyCount
    }
}
