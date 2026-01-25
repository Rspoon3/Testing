import Dependencies
import Foundation
import GRDB
import SQLiteData
import Testing
@testable import TestDrivePersistence
@testable import TestDriveCore

/// Tests for the APIKeyManager.
@Suite struct APIKeyManagerTests {

    let encryption: EncryptionService
    let keychain: KeychainService
    let vaultManager: VaultManager
    let apiKeyManager: APIKeyManager

    init() throws {
        // Set up in-memory database for testing
        let _ = prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }

        self.encryption = EncryptionService()
        self.keychain = KeychainService()
        self.vaultManager = VaultManager(
            encryption: encryption,
            keychain: keychain
        )
        self.apiKeyManager = APIKeyManager(
            encryption: encryption,
            vaultManager: vaultManager
        )
    }

    // MARK: - Key Creation Tests

    @Test func createKey() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let apiKey = try await apiKeyManager.createKey(
            label: "GitHub API Key",
            secret: "ghp_1234567890abcdef",
            vaultID: vault.id,
            websiteDomain: "github.com",
            company: "GitHub",
            environment: .production,
            tags: ["git", "vcs"],
            notes: "Production API key"
        )

        #expect(apiKey.label == "GitHub API Key")
        #expect(apiKey.websiteDomain == "github.com")
        #expect(apiKey.company == "GitHub")
        #expect(apiKey.environment == .production)
        #expect(apiKey.tags == ["git", "vcs"])
        #expect(apiKey.notes == "Production API key")
        #expect(apiKey.encryptedSecret.count > 0)
        #expect(apiKey.nonce.count == 12)

        // Clean up
        try await apiKeyManager.deleteKey(apiKey)
        try await vaultManager.deleteVault(vault)
    }

    @Test func createAndDecryptSecret() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let originalSecret = "sk-test-1234567890abcdef"
        let apiKey = try await apiKeyManager.createKey(
            label: "Test Key",
            secret: originalSecret,
            vaultID: vault.id
        )

        let decryptedSecret = try await apiKeyManager.getSecret(for: apiKey)

        #expect(decryptedSecret == originalSecret)

        // Clean up
        try await apiKeyManager.deleteKey(apiKey)
        try await vaultManager.deleteVault(vault)
    }

    // MARK: - Key Update Tests

    @Test func updateKey() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let apiKey = try await apiKeyManager.createKey(
            label: "Original Label",
            secret: "sk-test-123",
            vaultID: vault.id
        )

        var updated = apiKey
        updated.label = "Updated Label"
        updated.notes = "New notes"

        try await apiKeyManager.updateKey(updated)

        let keys = try await apiKeyManager.fetchKeys(in: vault.id)
        let found = keys.first { $0.id == apiKey.id }

        #expect(found?.label == "Updated Label")
        #expect(found?.notes == "New notes")

        // Clean up
        try await apiKeyManager.deleteKey(apiKey)
        try await vaultManager.deleteVault(vault)
    }

    // MARK: - Key Query Tests

    @Test func fetchKeysInVault() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let key1 = try await apiKeyManager.createKey(
            label: "Key 1",
            secret: "secret1",
            vaultID: vault.id
        )

        let key2 = try await apiKeyManager.createKey(
            label: "Key 2",
            secret: "secret2",
            vaultID: vault.id
        )

        let keys = try await apiKeyManager.fetchKeys(in: vault.id)

        #expect(keys.count == 2)

        // Clean up
        try await apiKeyManager.deleteKey(key1)
        try await apiKeyManager.deleteKey(key2)
        try await vaultManager.deleteVault(vault)
    }

    @Test func searchKeys() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let key1 = try await apiKeyManager.createKey(
            label: "GitHub Token",
            secret: "secret1",
            vaultID: vault.id,
            websiteDomain: "github.com"
        )

        let key2 = try await apiKeyManager.createKey(
            label: "GitLab Token",
            secret: "secret2",
            vaultID: vault.id,
            websiteDomain: "gitlab.com"
        )

        let results = try await apiKeyManager.searchKeys(query: "github")

        #expect(results.count == 1)
        #expect(results.first?.label == "GitHub Token")

        // Clean up
        try await apiKeyManager.deleteKey(key1)
        try await apiKeyManager.deleteKey(key2)
        try await vaultManager.deleteVault(vault)
    }

    @Test func fetchKeysByEnvironment() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let prodKey = try await apiKeyManager.createKey(
            label: "Production Key",
            secret: "secret1",
            vaultID: vault.id,
            environment: .production
        )

        let devKey = try await apiKeyManager.createKey(
            label: "Development Key",
            secret: "secret2",
            vaultID: vault.id,
            environment: .development
        )

        let prodKeys = try await apiKeyManager.fetchKeys(environment: .production, in: vault.id)
        let devKeys = try await apiKeyManager.fetchKeys(environment: .development, in: vault.id)

        #expect(prodKeys.count == 1)
        #expect(devKeys.count == 1)
        #expect(prodKeys.first?.label == "Production Key")
        #expect(devKeys.first?.label == "Development Key")

        // Clean up
        try await apiKeyManager.deleteKey(prodKey)
        try await apiKeyManager.deleteKey(devKey)
        try await vaultManager.deleteVault(vault)
    }

    @Test func fetchKeysByTags() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let key1 = try await apiKeyManager.createKey(
            label: "Key 1",
            secret: "secret1",
            vaultID: vault.id,
            tags: ["api", "production"]
        )

        let key2 = try await apiKeyManager.createKey(
            label: "Key 2",
            secret: "secret2",
            vaultID: vault.id,
            tags: ["database", "staging"]
        )

        let apiKeys = try await apiKeyManager.fetchKeys(withTags: ["api"], in: vault.id)

        #expect(apiKeys.count == 1)
        #expect(apiKeys.first?.label == "Key 1")

        // Clean up
        try await apiKeyManager.deleteKey(key1)
        try await apiKeyManager.deleteKey(key2)
        try await vaultManager.deleteVault(vault)
    }

    // MARK: - Key Statistics Tests

    @Test func keyCount() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let key1 = try await apiKeyManager.createKey(
            label: "Key 1",
            secret: "secret1",
            vaultID: vault.id
        )

        let key2 = try await apiKeyManager.createKey(
            label: "Key 2",
            secret: "secret2",
            vaultID: vault.id
        )

        let count = try await apiKeyManager.keyCount(in: vault.id)

        #expect(count == 2)

        // Clean up
        try await apiKeyManager.deleteKey(key1)
        try await apiKeyManager.deleteKey(key2)
        try await vaultManager.deleteVault(vault)
    }

    // MARK: - Mark as Used Tests

    @Test func markAsUsed() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let apiKey = try await apiKeyManager.createKey(
            label: "Test Key",
            secret: "secret",
            vaultID: vault.id
        )

        #expect(apiKey.lastUsedAt == nil)

        try await apiKeyManager.markAsUsed(apiKey)

        let keys = try await apiKeyManager.fetchKeys(in: vault.id)
        let found = keys.first { $0.id == apiKey.id }

        #expect(found?.lastUsedAt != nil)

        // Clean up
        try await apiKeyManager.deleteKey(apiKey)
        try await vaultManager.deleteVault(vault)
    }

    // MARK: - Rotation Tests

    @Test func fetchKeysNeedingRotation() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let expiredKey = try await apiKeyManager.createKey(
            label: "Expired Key",
            secret: "secret",
            vaultID: vault.id,
            rotateAt: pastDate
        )

        let rotationKeys = try await apiKeyManager.fetchKeysNeedingRotation()

        #expect(rotationKeys.count >= 1)
        #expect(rotationKeys.contains { $0.id == expiredKey.id })

        // Clean up
        try await apiKeyManager.deleteKey(expiredKey)
        try await vaultManager.deleteVault(vault)
    }

    // MARK: - End-to-End Integration Tests

    @Test func endToEndCreateVaultCreateKeyRetrieveSecret() async throws {
        // Create vault
        let vault = try await vaultManager.createVault(
            name: "Production Vault",
            iconName: "lock.shield.fill",
            colorHex: "#007AFF"
        )

        // Create API key
        let originalSecret = "sk-prod-9876543210fedcba"
        let apiKey = try await apiKeyManager.createKey(
            label: "Stripe API Key",
            secret: originalSecret,
            vaultID: vault.id,
            websiteDomain: "stripe.com",
            company: "Stripe",
            environment: .production,
            tags: ["payment", "production"],
            notes: "Main production Stripe key"
        )

        // Retrieve and verify secret
        let decryptedSecret = try await apiKeyManager.getSecret(for: apiKey)
        #expect(decryptedSecret == originalSecret)

        // Verify metadata
        #expect(apiKey.label == "Stripe API Key")
        #expect(apiKey.websiteDomain == "stripe.com")
        #expect(apiKey.company == "Stripe")
        #expect(apiKey.environment == .production)

        // Search for key
        let searchResults = try await apiKeyManager.searchKeys(query: "stripe")
        #expect(searchResults.count >= 1)
        #expect(searchResults.contains { $0.id == apiKey.id })

        // Clean up
        try await apiKeyManager.deleteKey(apiKey)
        try await vaultManager.deleteVault(vault)
    }
}
