import Foundation
import SQLiteData

/// Row type combining vault with its local-only preferences.
///
/// This table is created as a temporary view that joins Vault with VaultPreference,
/// allowing efficient querying of vaults with their pin status.
@Table
public struct VaultRow: Equatable, Sendable {
    /// The vault.
    public let vault: Vault

    /// Whether this vault is pinned to the top of the list.
    public let isPinned: Bool
}
