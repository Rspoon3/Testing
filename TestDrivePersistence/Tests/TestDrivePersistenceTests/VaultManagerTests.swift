import Dependencies
import Foundation
import GRDB
import SQLiteData
import Testing
@testable import TestDrivePersistence

/// Tests for the VaultManager.
@Suite struct VaultManagerTests {

    let encryption: EncryptionService
    let keychain: KeychainService
    let vaultManager: VaultManager

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
    }

    // MARK: - Vault Creation Tests

    @Test func createVault() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        #expect(vault.name == "Test Vault")
        #expect(vault.iconName == "lock.fill")
        #expect(vault.colorHex == "#FF0000")
        #expect(vault.ownerPublicKey.count == 32)

        // Verify vault key is cached
        let vaultKey = try await vaultManager.getVaultKey(for: vault.id)
        let vaultKeyData = encryption.keyToData(vaultKey)
        #expect(vaultKeyData.count == 32)

        // Clean up
        try await vaultManager.deleteVault(vault)
    }

    @Test func createMultipleVaults() async throws {
        let vault1 = try await vaultManager.createVault(
            name: "Vault 1",
            iconName: "1.circle",
            colorHex: "#FF0000"
        )

        let vault2 = try await vaultManager.createVault(
            name: "Vault 2",
            iconName: "2.circle",
            colorHex: "#00FF00"
        )

        let vaults = try await vaultManager.fetchAllVaults()
        #expect(vaults.count >= 2)

        // Clean up
        try await vaultManager.deleteVault(vault1)
        try await vaultManager.deleteVault(vault2)
    }

    // MARK: - Vault Key Management Tests

    @Test func getVaultKey() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        let vaultKey = try await vaultManager.getVaultKey(for: vault.id)
        let vaultKeyData = encryption.keyToData(vaultKey)

        #expect(vaultKeyData.count == 32)

        // Clean up
        try await vaultManager.deleteVault(vault)
    }

    @Test func getVaultKeyForNonexistentVault() async throws {
        let nonexistentID = UUID()

        await #expect(throws: VaultManagerError.vaultKeyNotFound) {
            try await vaultManager.getVaultKey(for: nonexistentID)
        }
    }

    // MARK: - Vault Update Tests

    @Test func updateVault() async throws {
        let vault = try await vaultManager.createVault(
            name: "Original Name",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        var updated = vault
        updated.name = "Updated Name"
        updated.colorHex = "#00FF00"

        try await vaultManager.updateVault(updated)

        let vaults = try await vaultManager.fetchAllVaults()
        let found = vaults.first { $0.id == vault.id }

        #expect(found?.name == "Updated Name")
        #expect(found?.colorHex == "#00FF00")

        // Clean up
        try await vaultManager.deleteVault(vault)
    }

    // MARK: - Vault Deletion Tests

    @Test func deleteVault() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        try await vaultManager.deleteVault(vault)

        // Verify vault key is deleted from Keychain
        await #expect(throws: VaultManagerError.vaultKeyNotFound) {
            try await vaultManager.getVaultKey(for: vault.id)
        }
    }

    // MARK: - Key Wrapping Tests

    @Test func wrapAndUnwrapVaultKey() async throws {
        let vault = try await vaultManager.createVault(
            name: "Test Vault",
            iconName: "lock.fill",
            colorHex: "#FF0000"
        )

        // Simulate recipient accepting share
        let recipientUserID = "test-recipient"
        try await vaultManager.onShareAccepted(vault: vault, recipientUserID: recipientUserID)

        // Get participant
        let participants = try await vaultManager.fetchParticipants(for: vault.id)
        guard let participant = participants.first else {
            Issue.record("No participant found")
            return
        }

        // Wrap key for recipient
        try await vaultManager.wrapKeyForRecipient(vault: vault, participant: participant)

        // Get wrapped key from database
        @Dependency(\.defaultDatabase) var database
        let wrappedKeys = try await database.read { db in
            try WrappedVaultKey
                .where { $0.vaultID.eq(vault.id) }
                .filter { $0.recipientUserID == recipientUserID }
                .fetchAll(db)
        }

        #expect(wrappedKeys.count == 1)

        if let wrappedKey = wrappedKeys.first {
            // Unwrap key
            try await vaultManager.unwrapKeyForVault(wrappedKey: wrappedKey)

            // Verify unwrapped key matches original
            let originalKey = try await vaultManager.getVaultKey(for: vault.id)
            let unwrappedKey = try keychain.getCachedVaultKey(for: vault.id)

            #expect(unwrappedKey == encryption.keyToData(originalKey))
        }

        // Clean up
        try await vaultManager.deleteVault(vault)
    }
}
