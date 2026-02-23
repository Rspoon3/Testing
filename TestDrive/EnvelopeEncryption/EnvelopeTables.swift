import Foundation
import SQLiteData

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

/// Per-credential metadata and wrapped item key.
///
/// The credential key (item key / DEK) is encrypted by the containing vault key.
@Table
struct Credential: Identifiable {
    /// Stable credential identifier.
    let id: UUID
    /// Owning vault.
    var vaultID: Vault.ID
    /// User-facing label for the credential.
    var label: String
    /// Credential key wrapped by the vault key.
    var wrappedCredentialKeyByVaultKey: Data
}

/// Encrypted secret payload for one credential field/value.
@Table
struct Secret: Identifiable {
    /// Stable secret identifier.
    let id: UUID
    /// Owning credential.
    var credentialID: Credential.ID
    /// Logical secret name (for example `apiKey`).
    var name: String
    /// AES-GCM combined representation encrypted by the credential key.
    var ciphertext: Data
}
