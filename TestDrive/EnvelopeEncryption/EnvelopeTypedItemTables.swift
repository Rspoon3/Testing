import Foundation
import SQLiteData

/// Metadata row for software-license items.
@Table
struct SoftwareLicenseItem: Identifiable {
    /// Stable type-row identifier.
    let id: UUID
    /// Owning item, expected to have `typeRawValue == softwareLicense`.
    var itemID: VaultItem.ID
    /// Publisher or issuing organization.
    var publisher: String
    /// Product name tied to the license.
    var productName: String
    /// Type-row creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

/// Encrypted field payload for software-license items.
@Table
struct SoftwareLicenseSecretField: Identifiable {
    /// Stable field identifier.
    let id: UUID
    /// Owning software-license item.
    var itemID: VaultItem.ID
    /// Logical field name.
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

/// Metadata row for username/password items.
@Table
struct UsernamePasswordItem: Identifiable {
    /// Stable type-row identifier.
    let id: UUID
    /// Owning item, expected to have `typeRawValue == usernamePassword`.
    var itemID: VaultItem.ID
    /// Display service name (for example "GitHub" or "AWS Console").
    var service: String
    /// Optional login URL.
    var loginURL: String?
    /// Type-row creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

/// Encrypted field payload for username/password items.
@Table
struct UsernamePasswordSecretField: Identifiable {
    /// Stable field identifier.
    let id: UUID
    /// Owning username/password item.
    var itemID: VaultItem.ID
    /// Logical field name (`username`, `password`, `otpSeed`, etc.).
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

/// Metadata row for personal-access-token items.
@Table
struct PersonalAccessTokenItem: Identifiable {
    /// Stable type-row identifier.
    let id: UUID
    /// Owning item, expected to have `typeRawValue == personalAccessToken`.
    var itemID: VaultItem.ID
    /// Token provider (for example `GitHub` or `GitLab`).
    var provider: String
    /// Human-readable token name.
    var tokenName: String
    /// Non-sensitive scope summary for display/search.
    var scopesHint: String?
    /// Type-row creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

/// Encrypted field payload for personal-access-token items.
@Table
struct PersonalAccessTokenSecretField: Identifiable {
    /// Stable field identifier.
    let id: UUID
    /// Owning personal-access-token item.
    var itemID: VaultItem.ID
    /// Logical field name (`token`, `refreshToken`, etc.).
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

/// Metadata row for database-credential items.
@Table
struct DatabaseCredentialItem: Identifiable {
    /// Stable type-row identifier.
    let id: UUID
    /// Owning item, expected to have `typeRawValue == databaseCredential`.
    var itemID: VaultItem.ID
    /// Database engine (`postgres`, `mysql`, `redis`, etc.).
    var engine: String
    /// Hostname or endpoint.
    var host: String
    /// Port number.
    var port: Int
    /// Database or schema name.
    var databaseName: String
    /// Type-row creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

/// Encrypted field payload for database-credential items.
@Table
struct DatabaseCredentialSecretField: Identifiable {
    /// Stable field identifier.
    let id: UUID
    /// Owning database-credential item.
    var itemID: VaultItem.ID
    /// Logical field name (`username`, `password`, `connectionString`, etc.).
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

/// Metadata row for mobile release-signing items.
@Table
struct MobileReleaseSigningItem: Identifiable {
    /// Stable type-row identifier.
    let id: UUID
    /// Owning item, expected to have `typeRawValue == mobileReleaseSigning`.
    var itemID: VaultItem.ID
    /// Platform (`iOS` or `Android`).
    var platform: String
    /// Bundle/application identifier.
    var appIdentifier: String
    /// Team ID or organization identifier.
    var teamOrOrgIdentifier: String
    /// Type-row creation timestamp.
    var createdAt: Date = .init()
    /// Last update timestamp.
    var updatedAt: Date = .init()
}

/// Encrypted field payload for mobile release-signing items.
@Table
struct MobileReleaseSigningSecretField: Identifiable {
    /// Stable field identifier.
    let id: UUID
    /// Owning mobile release-signing item.
    var itemID: VaultItem.ID
    /// Logical field name (`privateKey`, `p8Key`, `keystorePassword`, etc.).
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
