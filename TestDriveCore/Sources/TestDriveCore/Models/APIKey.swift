import Foundation
import SQLiteData

/// Represents an encrypted API key with metadata.
///
/// API keys are stored with end-to-end encryption. The secret is encrypted
/// using AES-256-GCM with the vault's encryption key. Metadata (label, domain,
/// tags, etc.) is stored unencrypted for searchability.
@Table
public struct APIKey: Identifiable, Sendable {
    /// Unique identifier for the API key.
    public let id: UUID

    /// User-facing label for the API key.
    public var label: String

    /// Website domain associated with the API key.
    public var websiteDomain: String?

    /// Company or service name associated with the API key.
    public var company: String?

    /// Environment type for the API key.
    public var environment: APIEnvironment

    /// Tags for categorizing and searching API keys (stored as comma-separated string).
    private var tagsString: String

    /// Date when the API key was created.
    public var createdAt: Date

    /// Optional date when the API key should be rotated.
    public var rotateAt: Date?

    /// Date when the API key was last used (copied).
    public var lastUsedAt: Date?

    /// User notes about the API key.
    public var notes: String

    /// Identifier of the vault containing this API key.
    public var vaultID: UUID

    /// Encrypted API key secret (AES-GCM ciphertext).
    ///
    /// The plaintext secret is encrypted using AES-256-GCM with the vault's
    /// encryption key. This ciphertext is safe to sync via CloudKit.
    public var encryptedSecret: Data

    /// Nonce for AES-GCM decryption (96 bits / 12 bytes).
    public var nonce: Data

    /// CloudKit record identifier.
    ///
    /// Managed by SQLiteData sync engine.
    public var ckRecordID: String?

    // MARK: - Computed Properties

    /// Tags for categorizing and searching API keys.
    public var tags: [String] {
        get {
            tagsString.isEmpty ? [] : tagsString.split(separator: ",").map(String.init)
        }
        set {
            tagsString = newValue.joined(separator: ",")
        }
    }

    // MARK: - Initializer

    /// Creates a new API key.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the API key. Defaults to a new UUID.
    ///   - label: User-facing label for the API key.
    ///   - websiteDomain: Website domain associated with the API key.
    ///   - company: Company or service name associated with the API key.
    ///   - environment: Environment type for the API key.
    ///   - tags: Tags for categorizing and searching API keys.
    ///   - createdAt: Date when the API key was created. Defaults to current date.
    ///   - rotateAt: Optional date when the API key should be rotated.
    ///   - lastUsedAt: Date when the API key was last used.
    ///   - notes: User notes about the API key.
    ///   - vaultID: Identifier of the vault containing this API key.
    ///   - encryptedSecret: Encrypted API key secret (AES-GCM ciphertext).
    ///   - nonce: Nonce for AES-GCM decryption.
    ///   - ckRecordID: CloudKit record identifier.
    public init(
        id: UUID = UUID(),
        label: String,
        websiteDomain: String? = nil,
        company: String? = nil,
        environment: APIEnvironment = .production,
        tags: [String] = [],
        createdAt: Date = Date(),
        rotateAt: Date? = nil,
        lastUsedAt: Date? = nil,
        notes: String = "",
        vaultID: UUID,
        encryptedSecret: Data,
        nonce: Data,
        ckRecordID: String? = nil
    ) {
        self.id = id
        self.label = label
        self.websiteDomain = websiteDomain
        self.company = company
        self.environment = environment
        self.tagsString = tags.joined(separator: ",")
        self.createdAt = createdAt
        self.rotateAt = rotateAt
        self.lastUsedAt = lastUsedAt
        self.notes = notes
        self.vaultID = vaultID
        self.encryptedSecret = encryptedSecret
        self.nonce = nonce
        self.ckRecordID = ckRecordID
    }
}
