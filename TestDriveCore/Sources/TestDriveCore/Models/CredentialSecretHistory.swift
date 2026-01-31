import Foundation
import SQLiteData
import StructuredQueriesCore

/// Audit log entry for credential secret rotations and updates.
///
/// When a secret's value is updated, the old value is moved to this history table
/// for audit purposes and potential rollback.
@Table
public struct CredentialSecretHistory: Identifiable, Sendable, Hashable {
    /// Unique identifier for this history entry.
    public let id: UUID

    /// Identifier of the secret this history entry belongs to.
    public let credentialSecretID: UUID

    /// Encrypted secret value at the time of replacement (AES-GCM ciphertext).
    public var encryptedSecret: Data

    /// Nonce for AES-GCM decryption (96 bits / 12 bytes).
    public var nonce: Data

    /// Date when this secret value was replaced.
    public var replacedAt: Date

    /// Reason for the secret rotation or update.
    public var reason: RotationReason

    // MARK: - Initializer

    /// Creates a new credential secret history entry.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - credentialSecretID: Identifier of the secret.
    ///   - encryptedSecret: Encrypted secret value at time of replacement.
    ///   - nonce: Nonce for AES-GCM decryption.
    ///   - replacedAt: Date when this secret value was replaced. Defaults to current date.
    ///   - reason: Reason for the rotation.
    public init(
        id: UUID = UUID(),
        credentialSecretID: UUID,
        encryptedSecret: Data,
        nonce: Data,
        replacedAt: Date = Date(),
        reason: RotationReason
    ) {
        self.id = id
        self.credentialSecretID = credentialSecretID
        self.encryptedSecret = encryptedSecret
        self.nonce = nonce
        self.replacedAt = replacedAt
        self.reason = reason
    }
}

/// Reason for rotating or updating a credential secret.
public enum RotationReason: String, Sendable, Codable {
    /// Reached scheduled expiration date.
    case expired

    /// Manual rotation initiated by user.
    case rotated

    /// Security incident or compromise suspected.
    case compromised

    /// User-initiated change without specific reason.
    case userInitiated
}

// MARK: - QueryRepresentable Conformance

extension RotationReason: QueryRepresentable, QueryBindable, QueryExpression {
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
