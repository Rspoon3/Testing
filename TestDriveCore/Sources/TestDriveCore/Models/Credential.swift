import Foundation
import SQLiteData

/// Represents a credential with metadata.
///
/// Credentials can contain multiple secrets (see CredentialSecret model).
/// Metadata (label, domain, tags, etc.) is stored unencrypted for searchability.
@Table
public struct Credential: Identifiable, Sendable, Hashable {
    /// Unique identifier for the credential.
    public let id: UUID

    /// User-facing label for the credential.
    public var label: String

    /// Website domain associated with the credential.
    public var websiteDomain: String?

    /// Company or service name associated with the credential.
    public var company: String?

    /// Environment type for the credential.
    public var environment: APIEnvironment

    /// Tags for categorizing and searching credentials (stored as comma-separated string).
    private var tagsString: String

    /// Date when the credential was created.
    public var createdAt: Date

    /// Optional date when the credential should be rotated.
    public var rotateAt: Date?

    /// Date when the credential was last used (copied).
    public var lastUsedAt: Date?

    /// User notes about the credential.
    public var notes: String

    /// Identifier of the vault containing this credential.
    public var vaultID: UUID

    /// CloudKit record identifier.
    ///
    /// Managed by SQLiteData sync engine.
    public var ckRecordID: String?

    // MARK: - Computed Properties

    /// Tags for categorizing and searching credentials.
    public var tags: [String] {
        get {
            tagsString.isEmpty ? [] : tagsString.split(separator: ",").map(String.init)
        }
        set {
            tagsString = newValue.joined(separator: ",")
        }
    }

    // MARK: - Initializer

    /// Creates a new credential.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the credential. Defaults to a new UUID.
    ///   - label: User-facing label for the credential.
    ///   - websiteDomain: Website domain associated with the credential.
    ///   - company: Company or service name associated with the credential.
    ///   - environment: Environment type for the credential.
    ///   - tags: Tags for categorizing and searching credentials.
    ///   - createdAt: Date when the credential was created. Defaults to current date.
    ///   - rotateAt: Optional date when the credential should be rotated.
    ///   - lastUsedAt: Date when the credential was last used.
    ///   - notes: User notes about the credential.
    ///   - vaultID: Identifier of the vault containing this credential.
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
        self.ckRecordID = ckRecordID
    }
}
