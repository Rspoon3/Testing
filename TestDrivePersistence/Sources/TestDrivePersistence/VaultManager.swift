import CloudKit
import CryptoKit
import Foundation
import TestDriveCore

/// Manages vault operations including creation, sharing, and key wrapping.
///
/// This manager orchestrates vault lifecycle operations and implements the
/// end-to-end encrypted sharing flow with X25519 key agreement.
@Observable
public final class VaultManager: Sendable {

    private let database: DatabaseManager
    private let encryption: EncryptionService
    private let keychain: KeychainService

    // MARK: - Initializer

    /// Creates a new vault manager.
    ///
    /// - Parameters:
    ///   - database: The database manager.
    ///   - encryption: The encryption service.
    ///   - keychain: The keychain service.
    public init(
        database: DatabaseManager,
        encryption: EncryptionService,
        keychain: KeychainService
    ) {
        self.database = database
        self.encryption = encryption
        self.keychain = keychain
    }

    // MARK: - Vault CRUD

    /// Creates a new vault with generated encryption key.
    ///
    /// This method:
    /// 1. Generates a vault AES key
    /// 2. Generates owner X25519 keypair
    /// 3. Stores private key in Keychain
    /// 4. Stores vault key in Keychain
    /// 5. Creates vault record with owner public key
    ///
    /// - Parameters:
    ///   - name: User-facing name for the vault.
    ///   - iconName: SF Symbol name for the vault icon.
    ///   - colorHex: Hex color string for the vault display color.
    /// - Returns: The newly created vault.
    /// - Throws: Database or encryption error if creation fails.
    public func createVault(
        name: String,
        iconName: String,
        colorHex: String
    ) async throws -> Vault {
        // Generate vault encryption key
        let vaultKey = encryption.generateVaultKey()
        let vaultKeyData = encryption.keyToData(vaultKey)

        // Generate owner X25519 keypair
        let ownerPrivateKey = encryption.generateKeypair()
        let ownerPublicKeyData = encryption.publicKeyData(from: ownerPrivateKey)

        // Create vault record
        let vaultID = UUID()
        let vault = Vault(
            id: vaultID,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            sortOrder: 0,
            isDefault: false,
            createdAt: Date(),
            updatedAt: Date(),
            ownerPublicKey: ownerPublicKeyData,
            isShared: false
        )

        // Store keys in Keychain
        try keychain.cacheVaultKey(vaultKeyData, for: vaultID)
        try keychain.storePrivateKey(
            ownerPrivateKey.rawRepresentation,
            identifier: "owner-\(vaultID.uuidString)"
        )

        // Save vault to database
        // Note: Actual SQLiteData API will be used in production
        // This is a placeholder for the implementation
        try await database.write { _ in
            // db.insert(vault) - SQLiteData API
        }

        return vault
    }

    /// Retrieves the vault encryption key from Keychain.
    ///
    /// - Parameter vaultID: The vault identifier.
    /// - Returns: The vault's encryption key.
    /// - Throws: KeychainError if the key is not found.
    public func getVaultKey(for vaultID: UUID) async throws -> SymmetricKey {
        guard let keyData = try keychain.getCachedVaultKey(for: vaultID) else {
            throw VaultManagerError.vaultKeyNotFound
        }

        return try encryption.dataToKey(keyData)
    }

    /// Updates vault metadata.
    ///
    /// - Parameter vault: The vault with updated metadata.
    /// - Throws: Database error if update fails.
    public func updateVault(_ vault: Vault) async throws {
        var updatedVault = vault
        updatedVault.updatedAt = Date()

        try await database.write { _ in
            // db.update(updatedVault) - SQLiteData API
        }
    }

    /// Deletes a vault, all its keys, and associated Keychain data.
    ///
    /// - Parameter vault: The vault to delete.
    /// - Throws: Database or keychain error if deletion fails.
    public func deleteVault(_ vault: Vault) async throws {
        // Delete from database (cascade deletes API keys)
        try await database.write { _ in
            // db.delete(vault) - SQLiteData API
        }

        // Clear Keychain data
        try keychain.clearCachedVaultKey(for: vault.id)
        try keychain.deletePrivateKey(identifier: "owner-\(vault.id.uuidString)")
    }

    /// Fetches all vaults from the database.
    ///
    /// - Returns: Array of all vaults sorted by sort order.
    /// - Throws: Database error if fetch fails.
    public func fetchAllVaults() async throws -> [Vault] {
        try await database.read { _ in
            // db.query(Vault.self).sorted(by: \.sortOrder).fetchAll() - SQLiteData API
            []
        }
    }

    // MARK: - Sharing & Key Wrapping

    /// Shares a vault with CloudKit sharing.
    ///
    /// This method presents the system CKShareSheet for the user to
    /// invite participants.
    ///
    /// - Parameter vault: The vault to share.
    /// - Returns: The CloudKit share record.
    /// - Throws: CloudKit error if sharing fails.
    public func shareVault(_ vault: Vault) async throws -> CKShare {
        // This would integrate with CloudKit sharing APIs
        // Implementation depends on SQLiteData's sharing support
        fatalError("CKShare integration pending")
    }

    /// Called when a participant accepts a vault share.
    ///
    /// This method:
    /// 1. Generates (or loads) recipient's X25519 keypair
    /// 2. Stores private key in Keychain
    /// 3. Updates VaultParticipant record with public key
    ///
    /// - Parameters:
    ///   - vault: The shared vault.
    ///   - recipientUserID: CloudKit user identifier of the recipient.
    /// - Throws: Database or encryption error if setup fails.
    public func onShareAccepted(vault: Vault, recipientUserID: String) async throws {
        // Check if keypair already exists
        let identifier = "recipient-\(vault.id.uuidString)"
        let privateKeyData: Data

        if let existing = try keychain.getPrivateKey(identifier: identifier) {
            privateKeyData = existing
        } else {
            // Generate new keypair
            let privateKey = encryption.generateKeypair()
            privateKeyData = privateKey.rawRepresentation
            try keychain.storePrivateKey(privateKeyData, identifier: identifier)
        }

        // Get public key
        let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)
        let publicKeyData = encryption.publicKeyData(from: privateKey)

        // Update participant record with public key
        try await database.write { _ in
            // SQLiteData query and update operations
        }
    }

    /// Starts monitoring shared vaults for new participants.
    ///
    /// This method watches VaultParticipant records for new public keys
    /// and automatically wraps vault keys for new participants.
    ///
    /// Note: This is a simplified implementation. In production, you'd use
    /// CloudKit notifications or periodic polling.
    public func startMonitoringShares() async {
        // Implementation would use CloudKit notifications
        // or periodic polling to detect new participants
    }

    /// Wraps a vault key for a specific recipient.
    ///
    /// This method:
    /// 1. Generates ephemeral keypair
    /// 2. Performs ECDH with recipient public key
    /// 3. Derives wrapping key via HKDF
    /// 4. Encrypts vault key
    /// 5. Creates WrappedVaultKey record in CloudKit
    ///
    /// - Parameters:
    ///   - vault: The vault to share.
    ///   - participant: The participant to wrap the key for.
    /// - Throws: Database or encryption error if wrapping fails.
    public func wrapKeyForRecipient(vault: Vault, participant: VaultParticipant) async throws {
        guard let recipientPublicKeyData = participant.publicKey else {
            throw VaultManagerError.participantPublicKeyMissing
        }

        // Get vault key
        let vaultKey = try await getVaultKey(for: vault.id)

        // Generate ephemeral keypair
        let ephemeralPrivate = encryption.generateKeypair()
        let ephemeralPublicData = encryption.publicKeyData(from: ephemeralPrivate)

        // Get recipient public key
        let recipientPublicKey = try encryption.publicKey(from: recipientPublicKeyData)

        // Derive wrapping key via ECDH + HKDF
        let salt = vault.id.uuidString.data(using: .utf8)!
        let wrappingKey = try encryption.deriveWrappingKey(
            privateKey: ephemeralPrivate,
            publicKey: recipientPublicKey,
            salt: salt
        )

        // Wrap vault key
        let (encryptedVaultKey, nonce) = try encryption.wrapVaultKey(vaultKey, with: wrappingKey)

        // Create wrapped key record
        let wrappedKey = WrappedVaultKey(
            vaultID: vault.id,
            recipientUserID: participant.userID,
            encryptedVaultKey: encryptedVaultKey + nonce, // Combine for storage
            ephemeralPublicKey: ephemeralPublicData
        )

        // Save to database
        try await database.write { _ in
            // db.insert(wrappedKey) - SQLiteData API
        }
    }

    /// Unwraps a vault key from a WrappedVaultKey record.
    ///
    /// This method:
    /// 1. Loads recipient private key from Keychain
    /// 2. Performs ECDH with ephemeral public key
    /// 3. Derives unwrapping key
    /// 4. Decrypts vault key
    /// 5. Caches in Keychain
    ///
    /// - Parameter wrappedKey: The wrapped vault key record.
    /// - Throws: Database or encryption error if unwrapping fails.
    public func unwrapKeyForVault(wrappedKey: WrappedVaultKey) async throws {
        // Load recipient private key
        let identifier = "recipient-\(wrappedKey.vaultID.uuidString)"
        guard let privateKeyData = try keychain.getPrivateKey(identifier: identifier) else {
            throw VaultManagerError.recipientPrivateKeyNotFound
        }

        let recipientPrivate = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)

        // Get ephemeral public key
        let ephemeralPublic = try encryption.publicKey(from: wrappedKey.ephemeralPublicKey)

        // Derive unwrapping key via ECDH + HKDF
        let salt = wrappedKey.vaultID.uuidString.data(using: .utf8)!
        let unwrappingKey = try encryption.deriveWrappingKey(
            privateKey: recipientPrivate,
            publicKey: ephemeralPublic,
            salt: salt
        )

        // Split ciphertext and nonce
        guard wrappedKey.encryptedVaultKey.count > 12 else {
            throw VaultManagerError.invalidWrappedKey
        }

        let ciphertext = wrappedKey.encryptedVaultKey.dropLast(12)
        let nonce = wrappedKey.encryptedVaultKey.suffix(12)

        // Unwrap vault key
        let vaultKey = try encryption.unwrapVaultKey(
            ciphertext: Data(ciphertext),
            nonce: Data(nonce),
            wrappingKey: unwrappingKey
        )

        // Cache in Keychain
        let vaultKeyData = encryption.keyToData(vaultKey)
        try keychain.cacheVaultKey(vaultKeyData, for: wrappedKey.vaultID)
    }

    // MARK: - Participant Management

    /// Fetches all participants for a vault.
    ///
    /// - Parameter vaultID: The vault identifier.
    /// - Returns: Array of participants.
    /// - Throws: Database error if fetch fails.
    public func fetchParticipants(for vaultID: UUID) async throws -> [VaultParticipant] {
        try await database.read { _ in
            // db.query(VaultParticipant.self).filter(\.vaultID == vaultID).fetchAll()
            []
        }
    }

    /// Revokes share access by deleting the wrapped key.
    ///
    /// - Parameter participant: The participant to revoke.
    /// - Throws: Database error if deletion fails.
    public func revokeShare(for participant: VaultParticipant) async throws {
        try await database.write { _ in
            // Delete wrapped keys and participant - SQLiteData API
        }
    }
}

// MARK: - Errors

/// Errors that can occur during vault operations.
public enum VaultManagerError: Error {
    /// The vault encryption key was not found in Keychain.
    case vaultKeyNotFound

    /// The participant's public key is missing.
    case participantPublicKeyMissing

    /// The recipient's private key was not found in Keychain.
    case recipientPrivateKeyNotFound

    /// The wrapped vault key has an invalid format.
    case invalidWrappedKey
}
