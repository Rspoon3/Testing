import Dependencies
import Foundation
import GRDB
import SQLiteData
import TestDriveCore

/// Manages credential operations including creation, encryption, and search.
///
/// This manager handles the full lifecycle of credentials, coordinating with
/// the VaultManager for encryption key access.
@MainActor
@Observable
public final class CredentialManager {

    @ObservationIgnored @Dependency(\.defaultDatabase) private var database
    private let encryption: EncryptionService
    private let vaultManager: VaultManager

    // MARK: - Initializer

    /// Creates a new credential manager.
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

    /// Creates a new credential with encrypted secret.
    ///
    /// - Parameters:
    ///   - label: User-facing label for the credential.
    ///   - secret: The plaintext credential secret to encrypt.
    ///   - vaultID: The vault to store the key in.
    ///   - websiteDomain: Optional website domain.
    ///   - company: Optional company name.
    ///   - environment: Environment type (defaults to production).
    ///   - tags: Tags for categorization.
    ///   - notes: User notes.
    ///   - rotateAt: Optional rotation reminder date.
    /// - Returns: The newly created credential.
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
    ) async throws -> Credential {
        // Get vault encryption key
        let vaultKey = try await vaultManager.getVaultKey(for: vaultID)

        // Encrypt secret
        let (ciphertext, nonce) = try encryption.encryptSecret(secret, with: vaultKey)

        // Create credential record
        let apiKey = Credential(
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
            try Credential.insert { apiKey }.execute(db)
        }

        return apiKey
    }

    /// Retrieves the decrypted secret for an credential.
    ///
    /// - Parameter key: The credential.
    /// - Returns: The plaintext secret.
    /// - Throws: Database or encryption error if decryption fails.
    public func getSecret(for key: Credential) async throws -> String {
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

    /// Updates an credential's metadata.
    ///
    /// Note: To update the secret, delete and recreate the key.
    ///
    /// - Parameter key: The credential with updated metadata.
    /// - Throws: Database error if update fails.
    public func updateKey(_ key: Credential) async throws {
        try await database.write { db in
            try Credential.update(key).execute(db)
        }
    }

    /// Deletes an credential.
    ///
    /// - Parameter key: The credential to delete.
    /// - Throws: Database error if deletion fails.
    public func deleteKey(_ key: Credential) async throws {
        try await database.write { db in
            try Credential.delete(key).execute(db)
        }
    }

    /// Marks an credential as recently used.
    ///
    /// Updates the lastUsedAt timestamp, useful for tracking key activity.
    ///
    /// - Parameter key: The credential that was used.
    /// - Throws: Database error if update fails.
    public func markAsUsed(_ key: Credential) async throws {
        var updated = key
        updated.lastUsedAt = Date()

        try await updateKey(updated)
    }

    /// Toggles the pinned state of an credential.
    ///
    /// - Parameter key: The credential to toggle.
    /// - Throws: Database error if update fails.
    public func toggleKeyPin(_ key: Credential) async throws {
        try await database.write { db in
            // Fetch existing preferences
            let existing = try CredentialPreference
                .where { $0.apiKeyID.eq(key.id) }
                .fetchOne(db)

            if var preference = existing {
                // Update existing
                preference.isPinned.toggle()
                try CredentialPreference.update(preference).execute(db)
            } else {
                // Create new preferences with isPinned = true
                let preference = CredentialPreference(apiKeyID: key.id, isPinned: true)
                try CredentialPreference.insert { preference }.execute(db)
            }
        }
    }

    // MARK: - Query Operations

    /// Fetches all credentials in a vault.
    ///
    /// - Parameter vaultID: The vault identifier.
    /// - Returns: Array of credentials sorted by creation date (newest first).
    /// - Throws: Database error if fetch fails.
    public func fetchKeys(in vaultID: UUID) async throws -> [Credential] {
        try await database.read { db in
            try Credential
                .where { $0.vaultID.eq(vaultID) }
                .order { $0.createdAt.desc() }
                .fetchAll(db)
        }
    }

    /// Fetches all credentials across all vaults.
    ///
    /// - Returns: Array of all credentials sorted by creation date.
    /// - Throws: Database error if fetch fails.
    public func fetchAllKeys() async throws -> [Credential] {
        try await database.read { db in
            try Credential
                .order { $0.createdAt.desc() }
                .fetchAll(db)
        }
    }

    /// Searches credentials by query string.
    ///
    /// Searches in label, domain, company, and tags.
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - vaultID: Optional vault to limit search to.
    /// - Returns: Array of matching credentials.
    /// - Throws: Database error if search fails.
    public func searchKeys(query: String, in vaultID: UUID? = nil) async throws -> [Credential] {
        let lowercaseQuery = query.lowercased()

        return try await database.read { db in
            let allKeys: [Credential]

            if let vaultID {
                allKeys = try Credential
                    .where { $0.vaultID.eq(vaultID) }
                    .fetchAll(db)
            } else {
                allKeys = try Credential.fetchAll(db)
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

    /// Fetches credentials needing rotation.
    ///
    /// Returns keys with rotateAt dates in the past or within the next 7 days.
    ///
    /// - Returns: Array of keys needing rotation.
    /// - Throws: Database error if fetch fails.
    public func fetchKeysNeedingRotation() async throws -> [Credential] {
        let warningDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        return try await database.read { db in
            let allKeys = try Credential
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

    /// Fetches credentials by environment.
    ///
    /// - Parameters:
    ///   - environment: The environment to filter by.
    ///   - vaultID: Optional vault to limit search to.
    /// - Returns: Array of matching credentials.
    /// - Throws: Database error if fetch fails.
    public func fetchKeys(
        environment: APIEnvironment,
        in vaultID: UUID? = nil
    ) async throws -> [Credential] {
        try await database.read { db in
            if let vaultID {
                // Fetch by environment then filter by vaultID
                return try Credential
                    .where { $0.environment.eq(environment) }
                    .order { $0.createdAt.desc() }
                    .fetchAll(db)
                    .filter { $0.vaultID == vaultID }
            } else {
                return try Credential
                    .where { $0.environment.eq(environment) }
                    .order { $0.createdAt.desc() }
                    .fetchAll(db)
            }
        }
    }

    /// Fetches credentials by tags.
    ///
    /// - Parameters:
    ///   - tags: The tags to search for (OR logic).
    ///   - vaultID: Optional vault to limit search to.
    /// - Returns: Array of matching credentials.
    /// - Throws: Database error if fetch fails.
    public func fetchKeys(
        withTags tags: [String],
        in vaultID: UUID? = nil
    ) async throws -> [Credential] {
        try await database.read { db in
            let allKeys: [Credential]

            if let vaultID {
                allKeys = try Credential
                    .where { $0.vaultID.eq(vaultID) }
                    .fetchAll(db)
            } else {
                allKeys = try Credential.fetchAll(db)
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
            try Credential
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
