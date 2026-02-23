import Foundation
import SQLiteData
import StructuredQueriesCore

/// Supported high-level item families.
///
/// All of these are represented by the same generic credential/field tables.
enum VaultItemType: String, Codable, QueryBindable {
    case genericSecret
    case usernamePassword
    case sshKey
    case personalAccessToken
    case databaseCredential
    case mobileReleaseSigning
    case softwareLicense
}

/// Non-secret metadata attribute kinds attached to a credential.
enum CredentialAttributeKind: String, Codable {
    case environment
    case link
    case associatedEmail
    case note
    case custom
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

/// Generic credential metadata and wrapped item key.
///
/// The item key (DEK) is encrypted by the containing vault key.
@Table
struct VaultItem: Identifiable {
    /// Stable item identifier.
    let id: UUID
    /// Owning vault.
    var vaultID: Vault.ID
    /// User-facing credential label.
    var title: String
    /// Logical item type discriminator.
    var type: VaultItemType
    /// Payload schema version for this item type.
    var payloadVersion: Int
    /// Item key wrapped by the vault key.
    var wrappedItemKeyByVaultKey: Data
    /// Item creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

/// Encrypted field payload for credential secret fields.
@Table
struct GenericItemSecretField: Identifiable {
    /// Stable field identifier.
    let id: UUID
    /// Owning item.
    var itemID: VaultItem.ID
    /// User-facing secret field label (for example `apiKey` or `password`).
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

/// Generic non-secret metadata entry for a credential.
@Table
struct CredentialAttribute: Identifiable {
    /// Stable attribute identifier.
    let id: UUID
    /// Owning credential.
    var credentialID: VaultItem.ID
    /// Attribute kind discriminator.
    var kindRawValue: String
    /// Attribute label (for example `environment` or `url`).
    var name: String
    /// Attribute value.
    var value: String
    /// Attribute creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

/// Encrypted file payload attached to a credential.
@Table
struct CredentialSecretFile: Identifiable {
    /// Stable file identifier.
    let id: UUID
    /// Owning credential.
    var credentialID: VaultItem.ID
    /// User-facing file label (for example `App Store Connect Key`). 
    var label: String
    /// Original file name (for example `AuthKey_ABC123DEFG.p8`).
    var fileName: String
    /// Optional media type (`application/x-pkcs8`, etc.).
    var mimeType: String?
    /// Ciphertext format/algorithm version.
    var cryptoVersion: Int
    /// AES-GCM combined representation encrypted by the credential key.
    var ciphertext: Data
    /// File creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

typealias Credential = VaultItem
typealias CredentialSecretField = GenericItemSecretField
typealias Secret = GenericItemSecretField
