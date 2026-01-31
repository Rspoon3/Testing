import Foundation

/// Aggregate view combining a credential with its associated secrets.
///
/// This model is used for displaying and managing credentials with their multiple secrets.
/// It provides computed properties for checking secret health status.
public struct CredentialWithSecrets: Identifiable, Sendable {
    /// The credential metadata.
    public let credential: Credential

    /// The list of secrets belonging to this credential.
    public let secrets: [CredentialSecret]

    /// Unique identifier (delegates to credential's ID).
    public var id: UUID { credential.id }

    // MARK: - Computed Properties

    /// Whether any of the secrets have expired.
    public var hasExpiredSecrets: Bool {
        secrets.contains { $0.isExpired }
    }

    /// Whether any of the secrets need rotation.
    public var needsRotation: Bool {
        secrets.contains { $0.needsRotation }
    }

    /// Whether all secrets are active (not expired or revoked).
    public var allSecretsActive: Bool {
        secrets.allSatisfy { $0.status == .active }
    }

    /// Count of secrets in this credential.
    public var secretCount: Int {
        secrets.count
    }

    // MARK: - Initializer

    /// Creates a new credential with secrets aggregate.
    ///
    /// - Parameters:
    ///   - credential: The credential metadata.
    ///   - secrets: The list of secrets belonging to this credential.
    public init(credential: Credential, secrets: [CredentialSecret]) {
        self.credential = credential
        self.secrets = secrets
    }
}
