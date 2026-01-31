import Dependencies
import Foundation
import GRDB
import SQLiteData
import TestDriveCore

/// Manages credential operations including creation, encryption, and multi-secret support.
///
/// This manager handles the full lifecycle of credentials with multiple secrets,
/// coordinating with the VaultManager for encryption key access.
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

    /// Creates a new credential with multiple encrypted secrets.
    ///
    /// - Parameters:
    ///   - label: User-facing label for the credential.
    ///   - secrets: Array of (label, value) tuples for the secrets.
    ///   - vaultID: The vault to store the credential in.
    ///   - websiteDomain: Optional website domain.
    ///   - company: Optional company name.
    ///   - environment: Environment type (defaults to production).
    ///   - tags: Tags for categorization.
    ///   - notes: User notes.
    ///   - rotateAt: Optional rotation reminder date.
    /// - Returns: The newly created credential with secrets.
    /// - Throws: Database or encryption error if creation fails.
    public func createCredential(
        label: String,
        secrets: [(label: String, value: String)],
        vaultID: UUID,
        websiteDomain: String? = nil,
        company: String? = nil,
        environment: APIEnvironment = .production,
        tags: [String] = [],
        notes: String = "",
        rotateAt: Date? = nil
    ) async throws -> CredentialWithSecrets {
        guard !secrets.isEmpty else {
            throw CredentialError.noSecretsProvided
        }

        // Get vault encryption key
        let vaultKey = try await vaultManager.getVaultKey(for: vaultID)

        // Create credential record (metadata only)
        let credential = Credential(
            label: label,
            websiteDomain: websiteDomain,
            company: company,
            environment: environment,
            tags: tags,
            createdAt: Date(),
            rotateAt: rotateAt,
            notes: notes,
            vaultID: vaultID
        )

        // Encrypt and create secret records
        var credentialSecrets: [CredentialSecret] = []
        for (index, secretPair) in secrets.enumerated() {
            let (ciphertext, nonce) = try encryption.encryptSecret(secretPair.value, with: vaultKey)

            let secret = CredentialSecret(
                credentialID: credential.id,
                secretLabel: secretPair.label,
                encryptedSecret: ciphertext,
                nonce: nonce,
                sortOrder: index
            )
            credentialSecrets.append(secret)
        }

        // Save to database
        try await database.write { db in
            try Credential.insert { credential }.execute(db)
            for secret in credentialSecrets {
                try CredentialSecret.insert { secret }.execute(db)
            }
        }

        return CredentialWithSecrets(credential: credential, secrets: credentialSecrets)
    }

    /// Retrieves all decrypted secrets for a credential.
    ///
    /// - Parameter credential: The credential.
    /// - Returns: Dictionary mapping secret labels to plaintext values.
    /// - Throws: Database or encryption error if decryption fails.
    public func getSecrets(for credential: Credential) async throws -> [String: String] {
        // Fetch secrets from database
        let secrets = try await database.read { db in
            try CredentialSecret
                .where { $0.credentialID.eq(credential.id) }
                .order { $0.sortOrder }
                .fetchAll(db)
        }

        // Get vault encryption key
        let vaultKey = try await vaultManager.getVaultKey(for: credential.vaultID)

        // Decrypt all secrets
        var decrypted: [String: String] = [:]
        for secret in secrets {
            let plaintext = try encryption.decryptSecret(
                ciphertext: secret.encryptedSecret,
                nonce: secret.nonce,
                vaultKey: vaultKey
            )
            decrypted[secret.secretLabel] = plaintext
        }

        return decrypted
    }

    /// Retrieves a single decrypted secret by label.
    ///
    /// - Parameters:
    ///   - credential: The credential.
    ///   - label: The secret label.
    /// - Returns: The plaintext secret value.
    /// - Throws: Database or encryption error if not found or decryption fails.
    public func getSecret(for credential: Credential, label: String) async throws -> String {
        // Fetch specific secret
        let secret = try await database.read { db in
            try CredentialSecret
                .where { $0.credentialID.eq(credential.id) && $0.secretLabel.eq(label) }
                .fetchOne(db)
        }

        guard let secret else {
            throw CredentialError.secretNotFound(label)
        }

        // Get vault encryption key
        let vaultKey = try await vaultManager.getVaultKey(for: credential.vaultID)

        // Decrypt secret
        return try encryption.decryptSecret(
            ciphertext: secret.encryptedSecret,
            nonce: secret.nonce,
            vaultKey: vaultKey
        )
    }

    /// Adds a new secret to an existing credential.
    ///
    /// - Parameters:
    ///   - credential: The credential to add to.
    ///   - label: Label for the new secret.
    ///   - value: Plaintext value to encrypt.
    ///   - expiresAt: Optional expiration date.
    ///   - rotateAt: Optional rotation reminder date.
    /// - Throws: Database or encryption error if creation fails.
    public func addSecret(
        to credential: Credential,
        label: String,
        value: String,
        expiresAt: Date? = nil,
        rotateAt: Date? = nil
    ) async throws {
        // Get vault encryption key
        let vaultKey = try await vaultManager.getVaultKey(for: credential.vaultID)

        // Encrypt secret
        let (ciphertext, nonce) = try encryption.encryptSecret(value, with: vaultKey)

        // Get next sort order
        let maxSortOrder = try await database.read { db in
            try CredentialSecret
                .where { $0.credentialID.eq(credential.id) }
                .select { max($0.sortOrder) }
                .fetchOne(db) ?? -1
        }

        let secret = CredentialSecret(
            credentialID: credential.id,
            secretLabel: label,
            encryptedSecret: ciphertext,
            nonce: nonce,
            sortOrder: maxSortOrder + 1,
            expiresAt: expiresAt,
            rotateAt: rotateAt
        )

        try await database.write { db in
            try CredentialSecret.insert { secret }.execute(db)
        }
    }

    /// Updates a secret's value with history tracking.
    ///
    /// - Parameters:
    ///   - credential: The credential.
    ///   - label: The secret label to update.
    ///   - newValue: New plaintext value.
    ///   - reason: Reason for the update.
    ///   - expiresAt: Optional new expiration date.
    ///   - rotateAt: Optional new rotation reminder date.
    /// - Throws: Database or encryption error if update fails.
    public func updateSecret(
        for credential: Credential,
        label: String,
        newValue: String,
        reason: RotationReason = .userInitiated,
        expiresAt: Date? = nil,
        rotateAt: Date? = nil
    ) async throws {
        // Fetch existing secret
        let secret = try await database.read { db in
            try CredentialSecret
                .where { $0.credentialID.eq(credential.id) && $0.secretLabel.eq(label) }
                .fetchOne(db)
        }

        guard var secret else {
            throw CredentialError.secretNotFound(label)
        }

        // Move old value to history
        let historyEntry = CredentialSecretHistory(
            credentialSecretID: secret.id,
            encryptedSecret: secret.encryptedSecret,
            nonce: secret.nonce,
            replacedAt: Date(),
            reason: reason
        )

        // Get vault encryption key
        let vaultKey = try await vaultManager.getVaultKey(for: credential.vaultID)

        // Encrypt new value
        let (ciphertext, nonce) = try encryption.encryptSecret(newValue, with: vaultKey)

        // Update secret
        secret.encryptedSecret = ciphertext
        secret.nonce = nonce
        secret.updatedAt = Date()
        if let expiresAt {
            secret.expiresAt = expiresAt
        }
        if let rotateAt {
            secret.rotateAt = rotateAt
        }

        // Update status based on expiration
        if let expiresAt, expiresAt < Date() {
            secret.status = .expired
        } else if secret.status == .expired {
            secret.status = .active
        }

        try await database.write { db in
            try CredentialSecretHistory.insert { historyEntry }.execute(db)
            try CredentialSecret.update(secret).execute(db)
        }
    }

    /// Deletes a secret from a credential.
    ///
    /// - Parameters:
    ///   - credential: The credential.
    ///   - label: The secret label to delete.
    /// - Throws: Error if trying to delete the last secret or database error.
    public func deleteSecret(for credential: Credential, label: String) async throws {
        // Check secret count
        let count = try await database.read { db in
            try CredentialSecret
                .where { $0.credentialID.eq(credential.id) }
                .fetchCount(db)
        }

        guard count > 1 else {
            throw CredentialError.cannotDeleteLastSecret
        }

        // Delete secret
        try await database.write { db in
            try CredentialSecret
                .where { $0.credentialID.eq(credential.id) && $0.secretLabel.eq(label) }
                .delete()
                .execute(db)
        }
    }

    /// Marks a secret as recently used.
    ///
    /// - Parameter secret: The secret that was used.
    /// - Throws: Database error if update fails.
    public func markSecretAsUsed(_ secret: CredentialSecret) async throws {
        var updated = secret
        updated.lastUsedAt = Date()

        try await database.write { db in
            try CredentialSecret.update(updated).execute(db)
        }
    }

    /// Retrieves the history of a secret.
    ///
    /// - Parameter secret: The secret.
    /// - Returns: Array of history entries, sorted by replacement date (newest first).
    /// - Throws: Database error if fetch fails.
    public func getSecretHistory(for secret: CredentialSecret) async throws -> [CredentialSecretHistory] {
        try await database.read { db in
            try CredentialSecretHistory
                .where { $0.credentialSecretID.eq(secret.id) }
                .order { $0.replacedAt.desc() }
                .fetchAll(db)
        }
    }

    /// Revokes a secret (marks as revoked, adds to history).
    ///
    /// - Parameters:
    ///   - credential: The credential.
    ///   - label: The secret label to revoke.
    ///   - reason: Reason for revocation.
    /// - Throws: Database error if update fails.
    public func revokeSecret(
        for credential: Credential,
        label: String,
        reason: String
    ) async throws {
        let secret = try await database.read { db in
            try CredentialSecret
                .where { $0.credentialID.eq(credential.id) && $0.secretLabel.eq(label) }
                .fetchOne(db)
        }

        guard var secret else {
            throw CredentialError.secretNotFound(label)
        }

        // Move to history
        let historyEntry = CredentialSecretHistory(
            credentialSecretID: secret.id,
            encryptedSecret: secret.encryptedSecret,
            nonce: secret.nonce,
            replacedAt: Date(),
            reason: .compromised
        )

        // Mark as revoked
        secret.status = .revoked
        secret.updatedAt = Date()

        try await database.write { db in
            try CredentialSecretHistory.insert { historyEntry }.execute(db)
            try CredentialSecret.update(secret).execute(db)
        }
    }

    /// Reorders secrets within a credential.
    ///
    /// - Parameters:
    ///   - credential: The credential.
    ///   - orderedLabels: Array of secret labels in desired order.
    /// - Throws: Database error if update fails.
    public func reorderSecrets(
        for credential: Credential,
        orderedLabels: [String]
    ) async throws {
        try await database.write { db in
            for (index, label) in orderedLabels.enumerated() {
                try CredentialSecret
                    .where { $0.credentialID.eq(credential.id) && $0.secretLabel.eq(label) }
                    .update { $0.sortOrder = index }
                    .execute(db)
            }
        }
    }

    /// Updates a credential's metadata.
    ///
    /// - Parameter credential: The credential with updated metadata.
    /// - Throws: Database error if update fails.
    public func updateCredential(_ credential: Credential) async throws {
        try await database.write { db in
            try Credential.update(credential).execute(db)
        }
    }

    /// Deletes a credential and all its secrets.
    ///
    /// - Parameter credential: The credential to delete.
    /// - Throws: Database error if deletion fails.
    public func deleteCredential(_ credential: Credential) async throws {
        try await database.write { db in
            try Credential.delete(credential).execute(db)
            // Secrets are cascade deleted via foreign key
        }
    }

    /// Marks a credential as recently used.
    ///
    /// Updates the lastUsedAt timestamp.
    ///
    /// - Parameter credential: The credential that was used.
    /// - Throws: Database error if update fails.
    public func markAsUsed(_ credential: Credential) async throws {
        var updated = credential
        updated.lastUsedAt = Date()

        try await updateCredential(updated)
    }

    /// Toggles the pinned state of a credential.
    ///
    /// - Parameter credential: The credential to toggle.
    /// - Throws: Database error if update fails.
    public func toggleKeyPin(_ credential: Credential) async throws {
        try await database.write { db in
            // Fetch existing preferences
            let existing = try CredentialPreference
                .where { $0.credentialID.eq(credential.id) }
                .fetchOne(db)

            if var preference = existing {
                // Update existing
                preference.isPinned.toggle()
                try CredentialPreference.update(preference).execute(db)
            } else {
                // Create new preferences with isPinned = true
                let preference = CredentialPreference(credentialID: credential.id, isPinned: true)
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
    public func fetchCredentials(in vaultID: UUID) async throws -> [Credential] {
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
    public func fetchAllCredentials() async throws -> [Credential] {
        try await database.read { db in
            try Credential
                .order { $0.createdAt.desc() }
                .fetchAll(db)
        }
    }

    /// Fetches a credential with all its secrets.
    ///
    /// - Parameter credentialID: The credential identifier.
    /// - Returns: Credential with secrets, or nil if not found.
    /// - Throws: Database error if fetch fails.
    public func fetchCredentialWithSecrets(_ credentialID: UUID) async throws -> CredentialWithSecrets? {
        try await database.read { db in
            guard let credential = try Credential
                .where { $0.id.eq(credentialID) }
                .fetchOne(db) else {
                return nil
            }

            let secrets = try CredentialSecret
                .where { $0.credentialID.eq(credentialID) }
                .order { $0.sortOrder }
                .fetchAll(db)

            return CredentialWithSecrets(credential: credential, secrets: secrets)
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
    public func searchCredentials(query: String, in vaultID: UUID? = nil) async throws -> [Credential] {
        let lowercaseQuery = query.lowercased()

        return try await database.read { db in
            let allCredentials: [Credential]

            if let vaultID {
                allCredentials = try Credential
                    .where { $0.vaultID.eq(vaultID) }
                    .fetchAll(db)
            } else {
                allCredentials = try Credential.fetchAll(db)
            }

            // Client-side filtering for text search
            return allCredentials.filter { credential in
                credential.label.lowercased().contains(lowercaseQuery) ||
                credential.websiteDomain?.lowercased().contains(lowercaseQuery) == true ||
                credential.company?.lowercased().contains(lowercaseQuery) == true ||
                credential.tags.contains { $0.lowercased().contains(lowercaseQuery) }
            }
        }
    }

    /// Fetches credentials needing rotation.
    ///
    /// Returns credentials with rotateAt dates in the past or within the next 7 days.
    ///
    /// - Returns: Array of credentials needing rotation.
    /// - Throws: Database error if fetch fails.
    public func fetchCredentialsNeedingRotation() async throws -> [Credential] {
        let warningDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        return try await database.read { db in
            let allCredentials = try Credential
                .order { $0.createdAt.desc() }
                .fetchAll(db)

            // Client-side filtering for optional date comparison
            return allCredentials.filter { credential in
                guard let rotateAt = credential.rotateAt else { return false }
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
    public func fetchCredentials(
        environment: APIEnvironment,
        in vaultID: UUID? = nil
    ) async throws -> [Credential] {
        try await database.read { db in
            if let vaultID {
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
    public func fetchCredentials(
        withTags tags: [String],
        in vaultID: UUID? = nil
    ) async throws -> [Credential] {
        try await database.read { db in
            let allCredentials: [Credential]

            if let vaultID {
                allCredentials = try Credential
                    .where { $0.vaultID.eq(vaultID) }
                    .fetchAll(db)
            } else {
                allCredentials = try Credential.fetchAll(db)
            }

            // Client-side filtering for tag matching
            return allCredentials.filter { credential in
                !Set(credential.tags).isDisjoint(with: Set(tags))
            }
        }
    }

    // MARK: - Statistics

    /// Counts the number of credentials in a vault.
    ///
    /// - Parameter vaultID: The vault identifier.
    /// - Returns: The number of credentials.
    /// - Throws: Database error if count fails.
    public func credentialCount(in vaultID: UUID) async throws -> Int {
        try await database.read { db in
            try Credential
                .where { $0.vaultID.eq(vaultID) }
                .fetchCount(db)
        }
    }

    /// Gets credential counts for multiple vaults.
    ///
    /// - Parameter vaultIDs: Array of vault identifiers.
    /// - Returns: Dictionary mapping vault IDs to credential counts.
    /// - Throws: Database error if counts fail.
    public func credentialCounts(for vaultIDs: [UUID]) async throws -> [UUID: Int] {
        var counts: [UUID: Int] = [:]

        for vaultID in vaultIDs {
            counts[vaultID] = try await credentialCount(in: vaultID)
        }

        return counts
    }

    // MARK: - Backward Compatibility (Deprecated)

    /// Legacy method for single-secret credentials.
    @available(*, deprecated, message: "Use createCredential(label:secrets:vaultID:...) instead")
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
        let result = try await createCredential(
            label: label,
            secrets: [("Secret", secret)],
            vaultID: vaultID,
            websiteDomain: websiteDomain,
            company: company,
            environment: environment,
            tags: tags,
            notes: notes,
            rotateAt: rotateAt
        )
        return result.credential
    }

    /// Legacy method for single-secret retrieval.
    @available(*, deprecated, message: "Use getSecrets(for:) or getSecret(for:label:) instead")
    public func getSecret(for credential: Credential) async throws -> String {
        let secrets = try await getSecrets(for: credential)
        guard let firstSecret = secrets.values.first else {
            throw CredentialError.noSecretsFound
        }
        return firstSecret
    }

    /// Legacy method name.
    @available(*, deprecated, renamed: "updateCredential")
    public func updateKey(_ credential: Credential) async throws {
        try await updateCredential(credential)
    }

    /// Legacy method name.
    @available(*, deprecated, renamed: "deleteCredential")
    public func deleteKey(_ credential: Credential) async throws {
        try await deleteCredential(credential)
    }

    /// Legacy method name.
    @available(*, deprecated, renamed: "fetchCredentials")
    public func fetchKeys(in vaultID: UUID) async throws -> [Credential] {
        try await fetchCredentials(in: vaultID)
    }

    /// Legacy method name.
    @available(*, deprecated, renamed: "fetchAllCredentials")
    public func fetchAllKeys() async throws -> [Credential] {
        try await fetchAllCredentials()
    }

    /// Legacy method name.
    @available(*, deprecated, renamed: "credentialCount")
    public func keyCount(in vaultID: UUID) async throws -> Int {
        try await credentialCount(in: vaultID)
    }
}

// MARK: - Errors

public enum CredentialError: LocalizedError {
    case noSecretsProvided
    case noSecretsFound
    case secretNotFound(String)
    case cannotDeleteLastSecret

    public var errorDescription: String? {
        switch self {
        case .noSecretsProvided:
            return "At least one secret is required"
        case .noSecretsFound:
            return "No secrets found for this credential"
        case .secretNotFound(let label):
            return "Secret '\(label)' not found"
        case .cannotDeleteLastSecret:
            return "Cannot delete the last secret. Delete the credential instead."
        }
    }
}
