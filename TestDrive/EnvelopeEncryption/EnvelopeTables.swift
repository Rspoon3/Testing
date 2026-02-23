import Foundation
import SQLiteData

/// Supported high-level item families.
///
/// Concrete tables can be added per type in future migrations
/// (for example username/password, SSH keys, software licenses).
enum VaultItemType: String, Codable {
    case genericSecret
    case usernamePassword
    case sshKey
    case personalAccessToken
    case databaseCredential
    case mobileReleaseSigning
    case softwareLicense
}

/// Persisted account-level wraps for the ARK.
@Table
struct AccountRootWrapRow: Identifiable {
    /// Account identifier (primary key).
    let id: UUID
    /// Salt used to derive the recovery wrap key.
    var recoverySalt: Data
    /// ARK wrapped by the recovery-derived wrap key.
    var wrappedARKByRecovery: Data
    /// Optional ARK wrapped by a sync wrap key.
    var wrappedARKBySync: Data?
}

/// Persisted ARK wrap for one enrolled device.
@Table
struct DeviceEnrollmentRow: Identifiable {
    /// Device identifier (primary key).
    let id: UUID
    /// Owning account identifier.
    var accountID: UUID
    /// ARK wrapped for this specific device wrap key.
    var wrappedARKByDevice: Data
}

/// Per-vault metadata and its wrapped vault key.
///
/// The vault key is encrypted by the account root key (ARK) and persisted as opaque data.
@Table
struct Vault: Identifiable {
    /// Stable vault identifier.
    let id: UUID
    /// User-facing vault name.
    var name: String
    /// Vault key wrapped by ARK.
    var wrappedVaultKeyByARK: Data
}

/// Per-item metadata and wrapped item key.
///
/// The item key (DEK) is encrypted by the containing vault key.
@Table
struct VaultItem: Identifiable {
    /// Stable item identifier.
    let id: UUID
    /// Owning vault.
    var vaultID: Vault.ID
    /// User-facing item title.
    var title: String
    /// Logical item type discriminator.
    var typeRawValue: String
    /// Payload schema version for this item type.
    var payloadVersion: Int
    /// Item key wrapped by the vault key.
    var wrappedItemKeyByVaultKey: Data
    /// Item creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

/// Encrypted field payload for the built-in generic item demo type.
///
/// Future item families can define dedicated per-type tables while reusing `VaultItem`.
@Table
struct GenericItemSecretField: Identifiable {
    /// Stable field identifier.
    let id: UUID
    /// Owning item.
    var itemID: VaultItem.ID
    /// Logical field name (for example `apiKey`).
    var fieldName: String
    /// Ciphertext format/algorithm version.
    var cryptoVersion: Int
    /// AES-GCM combined representation encrypted by the item key.
    var ciphertext: Data
    /// Field creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

typealias Credential = VaultItem
typealias Secret = GenericItemSecretField
