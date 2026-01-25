import Foundation
import SQLiteData

/// Represents a vault encryption key wrapped for a specific recipient.
///
/// This record contains the vault's encryption key encrypted with a derived
/// wrapping key from ECDH key agreement. Each participant gets their own
/// wrapped key record, enabling end-to-end encrypted vault sharing.
@Table
public struct WrappedVaultKey: Identifiable, Sendable {
    /// Unique identifier for the wrapped key record.
    public let id: UUID

    /// Identifier of the vault this key belongs to.
    public var vaultID: UUID

    /// CloudKit user identifier of the recipient.
    public var recipientUserID: String

    /// Vault encryption key wrapped with derived wrapping key.
    ///
    /// The vault's AES-256 key is encrypted using a wrapping key derived
    /// from ECDH key agreement between the owner's ephemeral private key
    /// and the recipient's public key.
    public var encryptedVaultKey: Data

    /// Owner's ephemeral X25519 public key.
    ///
    /// The recipient uses this public key with their private key to
    /// derive the same wrapping key via ECDH and unwrap the vault key.
    public var ephemeralPublicKey: Data

    /// Date when the vault key was wrapped.
    public var wrappedAt: Date

    /// CloudKit record identifier.
    ///
    /// Managed by SQLiteData sync engine.
    public var ckRecordID: String?

    // MARK: - Initializer

    /// Creates a new wrapped vault key record.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the wrapped key record. Defaults to a new UUID.
    ///   - vaultID: Identifier of the vault this key belongs to.
    ///   - recipientUserID: CloudKit user identifier of the recipient.
    ///   - encryptedVaultKey: Vault encryption key wrapped with derived wrapping key.
    ///   - ephemeralPublicKey: Owner's ephemeral X25519 public key.
    ///   - wrappedAt: Date when the vault key was wrapped. Defaults to current date.
    ///   - ckRecordID: CloudKit record identifier.
    public init(
        id: UUID = UUID(),
        vaultID: UUID,
        recipientUserID: String,
        encryptedVaultKey: Data,
        ephemeralPublicKey: Data,
        wrappedAt: Date = Date(),
        ckRecordID: String? = nil
    ) {
        self.id = id
        self.vaultID = vaultID
        self.recipientUserID = recipientUserID
        self.encryptedVaultKey = encryptedVaultKey
        self.ephemeralPublicKey = ephemeralPublicKey
        self.wrappedAt = wrappedAt
        self.ckRecordID = ckRecordID
    }
}
