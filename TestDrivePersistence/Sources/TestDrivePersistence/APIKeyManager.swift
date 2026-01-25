import Dependencies
import Foundation
import GRDB
import SQLiteData
import TestDriveCore

/// Manages API key operations including creation, encryption, and search.
///
/// This manager handles the full lifecycle of API keys, coordinating with
/// the VaultManager for encryption key access.
@MainActor
@Observable
public final class APIKeyManager {

    @ObservationIgnored @Dependency(\.defaultDatabase) private var database
    private let encryption: EncryptionService
    private let vaultManager: VaultManager

    // MARK: - Initializer

    /// Creates a new API key manager.
    ///
    /// - Parameters:
    ///   - encryption: The encryption service.
    ///   - vaultManager: The vault manager for key access.
    public init(
        encryption: EncryptionService,
        vaultManager: VaultManager
    ) {
        self.encryption = encryption
        self.vaultManager = vaultManager
    }

    // MARK: - CRUD Operations

    /// Creates a new API key with encrypted secret.
    ///
    /// - Parameters:
    ///   - label: User-facing label for the API key.
    ///   - secret: The plaintext API key secret to encrypt.
    ///   - vaultID: The vault to store the key in.
    ///   - websiteDomain: Optional website domain.
    ///   - company: Optional company name.
    ///   - environment: Environment type (defaults to production).
    ///   - tags: Tags for categorization.
    ///   - notes: User notes.
    ///   - rotateAt: Optional rotation reminder date.
    /// - Returns: The newly created API key.
    /// - Throws: Database or encryption error if creation fails.
    public func createKey(
        label: String,
        secret: String,
        vaultID: UUID,
        websiteDomain: String? = nil,
        company: String? = nil,
        environment: APIEnvironment = .production,
        tags: [String] = [],
        notes: String = "",
        rotateAt: Date? = nil
    ) async throws -> APIKey {
        // Get vault encryption key
        let vaultKey = try await vaultManager.getVaultKey(for: vaultID)

        // Encrypt secret
        let (ciphertext, nonce) = try encryption.encryptSecret(secret, with: vaultKey)

        // Create API key record
        let apiKey = APIKey(
            label: label,
            websiteDomain: websiteDomain,
            company: company,
            environment: environment,
            tags: tags,
            createdAt: Date(),
            rotateAt: rotateAt,
            notes: notes,
            vaultID: vaultID,
            encryptedSecret: ciphertext,
            nonce: nonce
        )

        // Save to database
        try await database.write { db in
            try APIKey.insert { apiKey }.execute(db)
        }

        return apiKey
    }

    /// Retrieves the decrypted secret for an API key.
    ///
    /// - Parameter key: The API key.
    /// - Returns: The plaintext secret.
    /// - Throws: Database or encryption error if decryption fails.
    public func getSecret(for key: APIKey) async throws -> String {
        // Get vault encryption key
        let vaultKey = try await vaultManager.getVaultKey(for: key.vaultID)

        // Decrypt secret
        let secret = try encryption.decryptSecret(
            ciphertext: key.encryptedSecret,
            nonce: key.nonce,
            vaultKey: vaultKey
        )

        return secret
    }

    /// Updates an API key's metadata.
    ///
    /// Note: To update the secret, delete and recreate the key.
    ///
    /// - Parameter key: The API key with updated metadata.
    /// - Throws: Database error if update fails.
    public func updateKey(_ key: APIKey) async throws {
        try await database.write { db in
            try APIKey.update(key).execute(db)
        }
    }

    /// Deletes an API key.
    ///
    /// - Parameter key: The API key to delete.
    /// - Throws: Database error if deletion fails.
    public func deleteKey(_ key: APIKey) async throws {
        try await database.write { db in
            try APIKey.delete(key).execute(db)
        }
    }

    /// Marks an API key as recently used.
    ///
    /// Updates the lastUsedAt timestamp, useful for tracking key activity.
    ///
    /// - Parameter key: The API key that was used.
    /// - Throws: Database error if update fails.
    public func markAsUsed(_ key: APIKey) async throws {
        var updated = key
        updated.lastUsedAt = Date()

        try await updateKey(updated)
    }

    // MARK: - Query Operations

    /// Fetches all API keys in a vault.
    ///
    /// - Parameter vaultID: The vault identifier.
    /// - Returns: Array of API keys sorted by creation date (newest first).
    /// - Throws: Database error if fetch fails.
    public func fetchKeys(in vaultID: UUID) async throws -> [APIKey] {
        try await database.read { db in
            try APIKey
                .where { $0.vaultID.eq(vaultID) }
                .order { $0.createdAt.desc() }
                .fetchAll(db)
        }
    }

    /// Fetches all API keys across all vaults.
    ///
    /// - Returns: Array of all API keys sorted by creation date.
    /// - Throws: Database error if fetch fails.
    public func fetchAllKeys() async throws -> [APIKey] {
        try await database.read { db in
            try APIKey
                .order { $0.createdAt.desc() }
                .fetchAll(db)
        }
    }

    /// Searches API keys by query string.
    ///
    /// Searches in label, domain, company, and tags.
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - vaultID: Optional vault to limit search to.
    /// - Returns: Array of matching API keys.
    /// - Throws: Database error if search fails.
    public func searchKeys(query: String, in vaultID: UUID? = nil) async throws -> [APIKey] {
        let lowercaseQuery = query.lowercased()

        return try await database.read { db in
            let allKeys: [APIKey]

            if let vaultID {
                allKeys = try APIKey
                    .where { $0.vaultID.eq(vaultID) }
                    .fetchAll(db)
            } else {
                allKeys = try APIKey.fetchAll(db)
            }

            // Client-side filtering for text search (SQLiteData doesn't support LIKE easily)
            return allKeys.filter { key in
                key.label.lowercased().contains(lowercaseQuery) ||
                key.websiteDomain?.lowercased().contains(lowercaseQuery) == true ||
                key.company?.lowercased().contains(lowercaseQuery) == true ||
                key.tags.contains { $0.lowercased().contains(lowercaseQuery) }
            }
        }
    }

    /// Fetches API keys needing rotation.
    ///
    /// Returns keys with rotateAt dates in the past or within the next 7 days.
    ///
    /// - Returns: Array of keys needing rotation.
    /// - Throws: Database error if fetch fails.
    public func fetchKeysNeedingRotation() async throws -> [APIKey] {
        let warningDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        return try await database.read { db in
            let allKeys = try APIKey
                .order { $0.createdAt.desc() }
                .fetchAll(db)

            // Client-side filtering for optional date comparison
            return allKeys.filter { key in
                guard let rotateAt = key.rotateAt else { return false }
                return rotateAt <= warningDate
            }
            .sorted { $0.rotateAt ?? Date.distantFuture < $1.rotateAt ?? Date.distantFuture }
        }
    }

    /// Fetches API keys by environment.
    ///
    /// - Parameters:
    ///   - environment: The environment to filter by.
    ///   - vaultID: Optional vault to limit search to.
    /// - Returns: Array of matching API keys.
    /// - Throws: Database error if fetch fails.
    public func fetchKeys(
        environment: APIEnvironment,
        in vaultID: UUID? = nil
    ) async throws -> [APIKey] {
        try await database.read { db in
            if let vaultID {
                // Fetch by environment then filter by vaultID
                return try APIKey
                    .where { $0.environment.eq(environment) }
                    .order { $0.createdAt.desc() }
                    .fetchAll(db)
                    .filter { $0.vaultID == vaultID }
            } else {
                return try APIKey
                    .where { $0.environment.eq(environment) }
                    .order { $0.createdAt.desc() }
                    .fetchAll(db)
            }
        }
    }

    /// Fetches API keys by tags.
    ///
    /// - Parameters:
    ///   - tags: The tags to search for (OR logic).
    ///   - vaultID: Optional vault to limit search to.
    /// - Returns: Array of matching API keys.
    /// - Throws: Database error if fetch fails.
    public func fetchKeys(
        withTags tags: [String],
        in vaultID: UUID? = nil
    ) async throws -> [APIKey] {
        try await database.read { db in
            let allKeys: [APIKey]

            if let vaultID {
                allKeys = try APIKey
                    .where { $0.vaultID.eq(vaultID) }
                    .fetchAll(db)
            } else {
                allKeys = try APIKey.fetchAll(db)
            }

            // Client-side filtering for tag matching
            return allKeys.filter { key in
                !Set(key.tags).isDisjoint(with: Set(tags))
            }
        }
    }

    // MARK: - Statistics

    /// Counts the number of keys in a vault.
    ///
    /// - Parameter vaultID: The vault identifier.
    /// - Returns: The number of keys.
    /// - Throws: Database error if count fails.
    public func keyCount(in vaultID: UUID) async throws -> Int {
        try await database.read { db in
            try APIKey
                .where { $0.vaultID.eq(vaultID) }
                .fetchCount(db)
        }
    }

    /// Gets key counts for multiple vaults.
    ///
    /// - Parameter vaultIDs: Array of vault identifiers.
    /// - Returns: Dictionary mapping vault IDs to key counts.
    /// - Throws: Database error if counts fail.
    public func keyCounts(for vaultIDs: [UUID]) async throws -> [UUID: Int] {
        var counts: [UUID: Int] = [:]

        for vaultID in vaultIDs {
            counts[vaultID] = try await keyCount(in: vaultID)
        }

        return counts
    }
}
