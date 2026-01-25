import Foundation
import Testing
@testable import TestDrivePersistence

/// Tests for the KeychainService.
@Suite struct KeychainServiceTests {

    let service = KeychainService()

    // MARK: - Vault Key Tests

    @Test func cacheAndRetrieveVaultKey() async throws {
        let vaultID = UUID()
        let key = Data(repeating: 42, count: 32)

        try service.cacheVaultKey(key, for: vaultID)

        let retrieved = try service.getCachedVaultKey(for: vaultID)

        #expect(retrieved == key)

        try service.clearCachedVaultKey(for: vaultID)
    }

    @Test func updateExistingVaultKey() async throws {
        let vaultID = UUID()
        let key1 = Data(repeating: 1, count: 32)
        let key2 = Data(repeating: 2, count: 32)

        try service.cacheVaultKey(key1, for: vaultID)

        try service.cacheVaultKey(key2, for: vaultID)

        let retrieved = try service.getCachedVaultKey(for: vaultID)
        #expect(retrieved == key2)

        try service.clearCachedVaultKey(for: vaultID)
    }

    @Test func retrieveNonExistentVaultKey() async throws {
        let vaultID = UUID()

        let retrieved = try service.getCachedVaultKey(for: vaultID)

        #expect(retrieved == nil)
    }

    @Test func clearVaultKey() async throws {
        let vaultID = UUID()
        let key = Data(repeating: 42, count: 32)

        try service.cacheVaultKey(key, for: vaultID)
        try service.clearCachedVaultKey(for: vaultID)

        let retrieved = try service.getCachedVaultKey(for: vaultID)
        #expect(retrieved == nil)
    }

    // MARK: - Private Key Tests

    @Test func storeAndRetrievePrivateKey() async throws {
        let identifier = UUID().uuidString
        let privateKey = Data(repeating: 99, count: 32)

        try service.storePrivateKey(privateKey, identifier: identifier)

        let retrieved = try service.getPrivateKey(identifier: identifier)

        #expect(retrieved == privateKey)

        try service.deletePrivateKey(identifier: identifier)
    }

    @Test func updateExistingPrivateKey() async throws {
        let identifier = UUID().uuidString
        let key1 = Data(repeating: 1, count: 32)
        let key2 = Data(repeating: 2, count: 32)

        try service.storePrivateKey(key1, identifier: identifier)

        try service.storePrivateKey(key2, identifier: identifier)

        let retrieved = try service.getPrivateKey(identifier: identifier)
        #expect(retrieved == key2)

        try service.deletePrivateKey(identifier: identifier)
    }

    @Test func retrieveNonExistentPrivateKey() async throws {
        let identifier = UUID().uuidString

        let retrieved = try service.getPrivateKey(identifier: identifier)

        #expect(retrieved == nil)
    }

    @Test func deletePrivateKey() async throws {
        let identifier = UUID().uuidString
        let privateKey = Data(repeating: 99, count: 32)

        try service.storePrivateKey(privateKey, identifier: identifier)
        try service.deletePrivateKey(identifier: identifier)

        let retrieved = try service.getPrivateKey(identifier: identifier)
        #expect(retrieved == nil)
    }

    // MARK: - Bulk Operations Tests

    @Test func clearAllCachedKeys() async throws {
        let vaultID1 = UUID()
        let vaultID2 = UUID()
        let key1 = Data(repeating: 1, count: 32)
        let key2 = Data(repeating: 2, count: 32)

        try service.cacheVaultKey(key1, for: vaultID1)
        try service.cacheVaultKey(key2, for: vaultID2)

        try service.clearAllCachedKeys()

        let retrieved1 = try service.getCachedVaultKey(for: vaultID1)
        let retrieved2 = try service.getCachedVaultKey(for: vaultID2)

        #expect(retrieved1 == nil)
        #expect(retrieved2 == nil)
    }
}
