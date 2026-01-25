import Foundation
import SQLiteData

/// Represents a secure vault for organizing API keys.
///
/// A vault is an encrypted container that groups related API keys together.
/// Each vault has its own encryption key and can be shared with other users
/// via CloudKit sharing with end-to-end encryption.
@Table
public struct Vault: Identifiable, Sendable, Equatable {
    /// Unique identifier for the vault.
    public let id: UUID

    /// User-facing name for the vault.
    public var name: String

    /// SF Symbol name for the vault icon.
    public var iconName: String

    /// Hex color string for the vault display color.
    public var colorHex: String

    /// Sort order for displaying vaults in lists.
    public var sortOrder: Int

    /// Indicates if this vault is pinned to the top of the list.
    public var isPinned: Bool

    /// Indicates if this is the default vault for new keys.
    public var isDefault: Bool

    /// Date when the vault was created.
    public var createdAt: Date

    /// Date when the vault was last updated.
    public var updatedAt: Date

    /// Owner's X25519 public key for key wrapping operations.
    ///
    /// This public key is used to wrap the vault encryption key
    /// for new participants via ECDH key agreement.
    public var ownerPublicKey: Data

    /// CloudKit record identifier.
    ///
    /// Managed by SQLiteData sync engine.
    public var ckRecordID: String?

    /// CloudKit share identifier.
    ///
    /// Present when the vault is shared with other users.
    public var ckShareID: String?

    /// Indicates if the vault is shared with other users.
    public var isShared: Bool

    /// CloudKit user identifier of the vault owner.
    public var ownerUserID: String?

    // MARK: - Initializer

    /// Creates a new vault.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the vault. Defaults to a new UUID.
    ///   - name: User-facing name for the vault.
    ///   - iconName: SF Symbol name for the vault icon.
    ///   - colorHex: Hex color string for the vault display color.
    ///   - sortOrder: Sort order for displaying vaults in lists.
    ///   - isPinned: Indicates if this vault is pinned to the top of the list.
    ///   - isDefault: Indicates if this is the default vault for new keys.
    ///   - createdAt: Date when the vault was created. Defaults to current date.
    ///   - updatedAt: Date when the vault was last updated. Defaults to current date.
    ///   - ownerPublicKey: Owner's X25519 public key for key wrapping operations.
    ///   - ckRecordID: CloudKit record identifier.
    ///   - ckShareID: CloudKit share identifier.
    ///   - isShared: Indicates if the vault is shared with other users.
    ///   - ownerUserID: CloudKit user identifier of the vault owner.
    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorHex: String,
        sortOrder: Int = 0,
        isPinned: Bool = false,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        ownerPublicKey: Data,
        ckRecordID: String? = nil,
        ckShareID: String? = nil,
        isShared: Bool = false,
        ownerUserID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isPinned = isPinned
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownerPublicKey = ownerPublicKey
        self.ckRecordID = ckRecordID
        self.ckShareID = ckShareID
        self.isShared = isShared
        self.ownerUserID = ownerUserID
    }
}
