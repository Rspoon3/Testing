import Foundation
import SQLiteData

/// Represents a user who has access to a shared vault.
///
/// Tracks participants in a shared vault, including their public keys
/// for encryption, permissions, and acceptance status.
@Table
public struct VaultParticipant: Identifiable, Sendable {
    /// Unique identifier for the participant record.
    public let id: UUID

    /// Identifier of the vault being shared.
    public var vaultID: UUID

    /// CloudKit user identifier (CKUserIdentity record name).
    public var userID: String

    /// Participant's X25519 public key for key wrapping.
    ///
    /// This public key is used to wrap the vault encryption key
    /// for this participant. It's `nil` until the participant accepts
    /// the share and generates their keypair.
    public var publicKey: Data?

    /// Permission level for this participant.
    public var permission: SharePermission

    /// Status of the share invitation.
    public var acceptanceStatus: AcceptanceStatus

    /// Date when the participant was added to the vault.
    public var addedAt: Date

    // MARK: - Initializer

    /// Creates a new vault participant record.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the participant record. Defaults to a new UUID.
    ///   - vaultID: Identifier of the vault being shared.
    ///   - userID: CloudKit user identifier.
    ///   - publicKey: Participant's X25519 public key.
    ///   - permission: Permission level for this participant.
    ///   - acceptanceStatus: Status of the share invitation.
    ///   - addedAt: Date when the participant was added. Defaults to current date.
    public init(
        id: UUID = UUID(),
        vaultID: UUID,
        userID: String,
        publicKey: Data? = nil,
        permission: SharePermission,
        acceptanceStatus: AcceptanceStatus = .pending,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.userID = userID
        self.publicKey = publicKey
        self.permission = permission
        self.acceptanceStatus = acceptanceStatus
        self.addedAt = addedAt
    }
}
