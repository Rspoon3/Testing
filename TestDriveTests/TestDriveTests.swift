//
//  TestDriveTests.swift
//  TestDriveTests
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import CryptoKit
import Foundation
import Testing
@testable import TestDrive

/// Behavioral tests for the minimal envelope architecture sample.
struct TestDriveTests {
    @Test
    /// Verifies payload decryption via device, recovery, and sync-unlock paths.
    func envelopeRoundTripAcrossDeviceRecoveryAndSyncPaths() throws {
        let recoveryCode = "correct horse battery staple"
        let accountID = UUID()
        let deviceAID = UUID()
        let deviceAWrapKey = SymmetricKey(size: .bits256)
        let syncWrapKey = SymmetricKey(size: .bits256)
        let databaseURL = try EnvelopePaths.temporaryDatabaseURL(testName: #function)
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        let metadataStore = AccountMetadataStore(database: database)
        let bootstrap = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: recoveryCode,
            initialDeviceID: deviceAID,
            initialDeviceWrapKey: deviceAWrapKey,
            metadataStore: metadataStore,
            syncWrapKey: syncWrapKey
        )
        let arkOnDeviceA = try AccountKeyCoordinator.unlockARKForDevice(
            metadataStore: metadataStore,
            accountID: accountID,
            deviceID: deviceAID,
            deviceWrapKey: deviceAWrapKey
        )
        let deviceAStore = EnvelopeStore(database: database, ark: arkOnDeviceA)

        let vaultID = try deviceAStore.createVault(name: "Primary Vault")
        let credentialID = try deviceAStore.createCredential(vaultID: vaultID, label: "Stripe")
        let secretID = try deviceAStore.addSecret(
            credentialID: credentialID,
            name: "apiKey",
            plaintext: Data("sk_test_123".utf8)
        )

        let recoveredARK = try AccountKeyCoordinator.recoverARK(
            metadataStore: metadataStore,
            accountID: accountID,
            recoveryCode: recoveryCode
        )
        let deviceBID = UUID()
        let deviceBWrapKey = SymmetricKey(size: .bits256)
        _ = try AccountKeyCoordinator.enrollDevice(
            metadataStore: metadataStore,
            accountID: accountID,
            ark: recoveredARK,
            deviceID: deviceBID,
            deviceWrapKey: deviceBWrapKey
        )
        let arkOnDeviceB = try AccountKeyCoordinator.unlockARKForDevice(
            metadataStore: metadataStore,
            accountID: accountID,
            deviceID: deviceBID,
            deviceWrapKey: deviceBWrapKey
        )
        let deviceBStore = EnvelopeStore(database: database, ark: arkOnDeviceB)
        let revealedOnDeviceB = try deviceBStore.revealSecret(secretID: secretID)
        #expect(String(decoding: revealedOnDeviceB, as: UTF8.self) == "sk_test_123")

        let arkFromSync = try AccountKeyCoordinator.unlockARKFromSync(
            metadataStore: metadataStore,
            accountID: accountID,
            syncWrapKey: syncWrapKey
        )
        let syncStore = EnvelopeStore(database: database, ark: arkFromSync)
        let revealedFromSync = try syncStore.revealSecret(secretID: secretID)
        #expect(String(decoding: revealedFromSync, as: UTF8.self) == "sk_test_123")
        #expect(bootstrap.rootWraps.accountID == accountID)
    }

    @Test
    /// Verifies recovery unlock fails with incorrect recovery code.
    func wrongRecoveryCodeFailsToUnwrapARK() throws {
        let accountID = UUID()
        let databaseURL = try EnvelopePaths.temporaryDatabaseURL(testName: #function)
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        let metadataStore = AccountMetadataStore(database: database)
        let bootstrap = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: "correct horse battery staple",
            initialDeviceID: UUID(),
            initialDeviceWrapKey: SymmetricKey(size: .bits256),
            metadataStore: metadataStore
        )

        var didThrow = false
        do {
            _ = try AccountKeyCoordinator.recoverARK(
                metadataStore: metadataStore,
                accountID: accountID,
                recoveryCode: "wrong recovery code"
            )
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(bootstrap.rootWraps.accountID == accountID)
    }

    @Test
    /// Verifies device unlock fails with incorrect device wrap key.
    func wrongDeviceWrapKeyFailsToUnwrapARK() throws {
        let accountID = UUID()
        let deviceID = UUID()
        let databaseURL = try EnvelopePaths.temporaryDatabaseURL(testName: #function)
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        let metadataStore = AccountMetadataStore(database: database)
        let bootstrap = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: "correct horse battery staple",
            initialDeviceID: deviceID,
            initialDeviceWrapKey: SymmetricKey(size: .bits256),
            metadataStore: metadataStore
        )

        var didThrow = false
        do {
            _ = try AccountKeyCoordinator.unlockARKForDevice(
                metadataStore: metadataStore,
                accountID: accountID,
                deviceID: deviceID,
                deviceWrapKey: SymmetricKey(size: .bits256)
            )
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(bootstrap.initialDevice.deviceID == deviceID)
    }

    @Test
    /// Verifies shared-vault provisioning policy semantics.
    func sharedVaultProvisioningPolicy() {
        let alice = UUID()
        let bob = UUID()

        #expect(
            SharedVaultProvisioningPolicy.canProvision(
                actorRole: .owner,
                actorPrincipalID: alice,
                targetPrincipalID: bob
            )
        )
        #expect(
            SharedVaultProvisioningPolicy.canProvision(
                actorRole: .viewer,
                actorPrincipalID: alice,
                targetPrincipalID: alice
            )
        )
        #expect(
            !SharedVaultProvisioningPolicy.canProvision(
                actorRole: .viewer,
                actorPrincipalID: alice,
                targetPrincipalID: bob
            )
        )
        #expect(
            SharedVaultProvisioningPolicy.canProvision(
                actorRole: .writer,
                actorPrincipalID: alice,
                targetPrincipalID: bob
            )
        )
        #expect(!SharedVaultProvisioningPolicy.canModifyMembership(actorRole: .viewer))
        #expect(!SharedVaultProvisioningPolicy.canRotateVaultKey(actorRole: .writer))
        #expect(SharedVaultProvisioningPolicy.canRotateVaultKey(actorRole: .owner))
    }
}
