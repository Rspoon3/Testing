import Foundation
import SQLiteData
import StructuredQueriesCore

/// Represents a single encrypted secret within a credential.
///
/// Credentials can have multiple secrets (e.g., AWS has "Access Key ID" and "Secret Access Key").
/// Each secret is encrypted independently with its own nonce for security.
@Table
public struct CredentialSecret: Identifiable, Sendable, Hashable {
    /// Unique identifier for this secret.
    public let id: UUID

    /// Identifier of the parent credential.
    public let credentialID: UUID

    /// User-facing label for this secret (e.g., "Access Key ID", "Client Secret").
    public var secretLabel: String

    /// Encrypted secret value (AES-GCM ciphertext).
    ///
    /// The plaintext value is encrypted using AES-256-GCM with the vault's encryption key.
    public var encryptedSecret: Data

    /// Nonce for AES-GCM decryption (96 bits / 12 bytes).
    public var nonce: Data

    /// Display order within the credential's secret list.
    public var sortOrder: Int

    /// Date when this secret was created.
    public var createdAt: Date

    /// Date when this secret's value was last changed.
    public var updatedAt: Date

    /// Date when this secret was last used (copied or revealed).
    public var lastUsedAt: Date?

    /// Number of times this secret has been copied to clipboard.
    public var copyCount: Int

    /// Optional expiration date for this secret.
    public var expiresAt: Date?

    /// Optional date when this secret should be rotated (reminder).
    public var rotateAt: Date?

    /// Current status of this secret.
    public var status: SecretStatus

    /// CloudKit record identifier.
    ///
    /// Managed by SQLiteData sync engine.
    public var ckRecordID: String?

    // MARK: - Computed Properties

    /// Whether this secret has expired.
    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    /// Whether this secret needs rotation.
    public var needsRotation: Bool {
        guard let rotateAt else { return false }
        return rotateAt < Date()
    }

    // MARK: - Initializer

    /// Creates a new credential secret.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - credentialID: Identifier of the parent credential.
    ///   - secretLabel: User-facing label for this secret.
    ///   - encryptedSecret: Encrypted secret value.
    ///   - nonce: Nonce for AES-GCM decryption.
    ///   - sortOrder: Display order within the credential's secret list.
    ///   - createdAt: Date when this secret was created. Defaults to current date.
    ///   - updatedAt: Date when this secret's value was last changed. Defaults to current date.
    ///   - lastUsedAt: Date when this secret was last used.
    ///   - copyCount: Number of times this secret has been copied. Defaults to 0.
    ///   - expiresAt: Optional expiration date.
    ///   - rotateAt: Optional rotation reminder date.
    ///   - status: Current status. Defaults to `.active`.
    ///   - ckRecordID: CloudKit record identifier.
    public init(
        id: UUID = UUID(),
        credentialID: UUID,
        secretLabel: String,
        encryptedSecret: Data,
        nonce: Data,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastUsedAt: Date? = nil,
        copyCount: Int = 0,
        expiresAt: Date? = nil,
        rotateAt: Date? = nil,
        status: SecretStatus = .active,
        ckRecordID: String? = nil
    ) {
        self.id = id
        self.credentialID = credentialID
        self.secretLabel = secretLabel
        self.encryptedSecret = encryptedSecret
        self.nonce = nonce
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.copyCount = copyCount
        self.expiresAt = expiresAt
        self.rotateAt = rotateAt
        self.status = status
        self.ckRecordID = ckRecordID
    }
}

/// Status of a credential secret in its lifecycle.
public enum SecretStatus: String, Sendable, Codable {
    /// Currently active and in use.
    case active

    /// Past its expiration date.
    case expired

    /// Manually revoked or disabled.
    case revoked
}

// MARK: - QueryRepresentable Conformance

extension SecretStatus: QueryRepresentable, QueryBindable, QueryExpression {
    public typealias QueryOutput = Self
    public typealias QueryValue = Self

    public static var _columnWidth: Int { 1 }

    public init(queryOutput: Self) {
        self = queryOutput
    }

    public var queryOutput: Self {
        self
    }
}
