//
//  TestDriveTests.swift
//  TestDriveTests
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import CryptoKit
import Dependencies
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
        let attemptTracker = RecoveryAttemptTracker(database: database)
        let bootstrap = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: attemptTracker
        ) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: recoveryCode,
                initialDeviceID: deviceAID,
                initialDeviceWrapKey: deviceAWrapKey,
                syncWrapKey: syncWrapKey
            )
        }
        let arkOnDeviceA = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: attemptTracker
        ) {
            try AccountKeyCoordinator.unlockARKForDevice(
                accountID: accountID,
                deviceID: deviceAID,
                deviceWrapKey: deviceAWrapKey
            )
        }
        let deviceAStore = EnvelopeStore(
            database: database,
            ark: arkOnDeviceA,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
        )

        let vaultID = try deviceAStore.createVault(name: "Primary Vault")
        let credentialID = try deviceAStore.createCredential(vaultID: vaultID, label: "Stripe")
        let secretID = try deviceAStore.addSecret(
            credentialID: credentialID,
            name: "apiKey",
            plaintext: Data("sk_test_123".utf8)
        )
        let softwareLicense = try deviceAStore.createCredential(
            vaultID: vaultID,
            label: "JetBrains All Products",
            type: .softwareLicense,
            initialSecretLabel: "licenseKey",
            initialSecretPlaintext: Data("JETBRAINS-DEMO-LICENSE".utf8)
        )

        let recoveredARK = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: attemptTracker
        ) {
            try AccountKeyCoordinator.recoverARK(
                accountID: accountID,
                recoveryCode: recoveryCode
            )
        }
        let deviceBID = UUID()
        let deviceBWrapKey = SymmetricKey(size: .bits256)
        _ = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: attemptTracker
        ) {
            try AccountKeyCoordinator.enrollDevice(
                accountID: accountID,
                ark: recoveredARK,
                deviceID: deviceBID,
                deviceWrapKey: deviceBWrapKey
            )
        }
        let arkOnDeviceB = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: attemptTracker
        ) {
            try AccountKeyCoordinator.unlockARKForDevice(
                accountID: accountID,
                deviceID: deviceBID,
                deviceWrapKey: deviceBWrapKey
            )
        }
        let deviceBStore = EnvelopeStore(
            database: database,
            ark: arkOnDeviceB,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
        )
        let revealedOnDeviceB = try deviceBStore.revealSecret(secretID: secretID)
        #expect(String(decoding: revealedOnDeviceB, as: UTF8.self) == "sk_test_123")
        let revealedLicenseOnDeviceB = try deviceBStore.revealSecret(
            secretID: softwareLicense.initialSecretFieldID
        )
        #expect(String(decoding: revealedLicenseOnDeviceB, as: UTF8.self) == "JETBRAINS-DEMO-LICENSE")

        let arkFromSync = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: attemptTracker
        ) {
            try AccountKeyCoordinator.unlockARKFromSync(
                accountID: accountID,
                syncWrapKey: syncWrapKey
            )
        }
        let syncStore = EnvelopeStore(
            database: database,
            ark: arkFromSync,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
        )
        let revealedFromSync = try syncStore.revealSecret(secretID: secretID)
        #expect(String(decoding: revealedFromSync, as: UTF8.self) == "sk_test_123")
        let revealedLicenseFromSync = try syncStore.revealSecret(
            secretID: softwareLicense.initialSecretFieldID
        )
        #expect(String(decoding: revealedLicenseFromSync, as: UTF8.self) == "JETBRAINS-DEMO-LICENSE")
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
        let attemptTracker = RecoveryAttemptTracker(database: database)
        let bootstrap = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: attemptTracker
        ) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: "correct horse battery staple",
                initialDeviceID: UUID(),
                initialDeviceWrapKey: SymmetricKey(size: .bits256)
            )
        }

        var didThrow = false
        do {
            _ = try withCoordinatorDependencies(
                metadataStore: metadataStore,
                attemptTracker: attemptTracker
            ) {
                try AccountKeyCoordinator.recoverARK(
                    accountID: accountID,
                    recoveryCode: "wrong recovery code"
                )
            }
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
        let attemptTracker = RecoveryAttemptTracker(database: database)
        let bootstrap = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: attemptTracker
        ) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: "correct horse battery staple",
                initialDeviceID: deviceID,
                initialDeviceWrapKey: SymmetricKey(size: .bits256)
            )
        }

        var didThrow = false
        do {
            _ = try withCoordinatorDependencies(
                metadataStore: metadataStore,
                attemptTracker: attemptTracker
            ) {
                try AccountKeyCoordinator.unlockARKForDevice(
                    accountID: accountID,
                    deviceID: deviceID,
                    deviceWrapKey: SymmetricKey(size: .bits256)
                )
            }
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(bootstrap.initialDevice.deviceID == deviceID)
    }

    @Test
    /// Verifies recovery succeeds with tracker and resets failure count.
    func recoveryWithTrackerSucceedsAndResetsFailures() throws {
        let accountID = UUID()
        let recoveryCode = "correct horse battery staple"
        let databaseURL = try EnvelopePaths.temporaryDatabaseURL(testName: #function)
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        let metadataStore = AccountMetadataStore(database: database)

        var currentDate = Date()
        let tracker = RecoveryAttemptTracker(
            database: database,
            policy: .default,
            now: { currentDate }
        )
        _ = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: tracker
        ) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: recoveryCode,
                initialDeviceID: UUID(),
                initialDeviceWrapKey: SymmetricKey(size: .bits256)
            )
        }

        // Fail once, then advance past backoff window
        #expect(throws: (any Error).self) {
            try withCoordinatorDependencies(
                metadataStore: metadataStore,
                attemptTracker: tracker
            ) {
                try AccountKeyCoordinator.recoverARK(
                    accountID: accountID,
                    recoveryCode: "wrong code"
                )
            }
        }
        currentDate = currentDate.addingTimeInterval(10)

        // Correct code succeeds and resets failure count
        let ark = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: tracker
        ) {
            try AccountKeyCoordinator.recoverARK(
                accountID: accountID,
                recoveryCode: recoveryCode
            )
        }
        #expect(ark.bitCount == 256)

        // Immediate retry with correct code works (no backoff after reset)
        let ark2 = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: tracker
        ) {
            try AccountKeyCoordinator.recoverARK(
                accountID: accountID,
                recoveryCode: recoveryCode
            )
        }
        #expect(ark2.bitCount == 256)
    }

    @Test
    /// Verifies exponential backoff blocks attempts too soon after failure.
    func recoveryRateLimitedAfterFailure() throws {
        let accountID = UUID()
        let databaseURL = try EnvelopePaths.temporaryDatabaseURL(testName: #function)
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        let metadataStore = AccountMetadataStore(database: database)

        var currentDate = Date()
        let policy = RecoveryAttemptTracker.Policy(baseDelay: 2, maxConsecutiveFailures: 10)
        let tracker = RecoveryAttemptTracker(
            database: database,
            policy: policy,
            now: { currentDate }
        )
        _ = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: tracker
        ) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: "correct horse battery staple",
                initialDeviceID: UUID(),
                initialDeviceWrapKey: SymmetricKey(size: .bits256)
            )
        }

        // First wrong attempt fails (crypto error, but failure is recorded)
        #expect(throws: (any Error).self) {
            try withCoordinatorDependencies(
                metadataStore: metadataStore,
                attemptTracker: tracker
            ) {
                try AccountKeyCoordinator.recoverARK(
                    accountID: accountID,
                    recoveryCode: "wrong"
                )
            }
        }

        // Immediate retry is rate-limited (2s backoff after 1 failure)
        #expect(throws: RecoveryAttemptTracker.TrackerError.self) {
            try tracker.checkAttemptAllowed(accountID: accountID)
        }

        // Advance 1s — still blocked
        currentDate = currentDate.addingTimeInterval(1)
        #expect(throws: RecoveryAttemptTracker.TrackerError.self) {
            try tracker.checkAttemptAllowed(accountID: accountID)
        }

        // Advance past 2s — allowed
        currentDate = currentDate.addingTimeInterval(1.5)
        try tracker.checkAttemptAllowed(accountID: accountID)
    }

    @Test
    /// Verifies lockout after exceeding maximum consecutive failures.
    func recoveryLockedOutAfterMaxFailures() throws {
        let accountID = UUID()
        let databaseURL = try EnvelopePaths.temporaryDatabaseURL(testName: #function)
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        let metadataStore = AccountMetadataStore(database: database)

        var currentDate = Date()
        let maxFailures = 3
        let policy = RecoveryAttemptTracker.Policy(baseDelay: 0.001, maxConsecutiveFailures: maxFailures)
        let tracker = RecoveryAttemptTracker(
            database: database,
            policy: policy,
            now: { currentDate }
        )
        _ = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: tracker
        ) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: "correct horse battery staple",
                initialDeviceID: UUID(),
                initialDeviceWrapKey: SymmetricKey(size: .bits256)
            )
        }

        // Exhaust all allowed attempts
        for _ in 0..<maxFailures {
            currentDate = currentDate.addingTimeInterval(100)
            #expect(throws: (any Error).self) {
                try withCoordinatorDependencies(
                    metadataStore: metadataStore,
                    attemptTracker: tracker
                ) {
                    try AccountKeyCoordinator.recoverARK(
                        accountID: accountID,
                        recoveryCode: "wrong"
                    )
                }
            }
        }

        // Next attempt is permanently locked — even with lots of time elapsed
        currentDate = currentDate.addingTimeInterval(999_999)
        #expect(throws: RecoveryAttemptTracker.TrackerError.self) {
            try tracker.checkAttemptAllowed(accountID: accountID)
        }

        // Manual reset re-enables recovery
        try tracker.resetLockout(accountID: accountID)
        let ark = try withCoordinatorDependencies(
            metadataStore: metadataStore,
            attemptTracker: tracker
        ) {
            try AccountKeyCoordinator.recoverARK(
                accountID: accountID,
                recoveryCode: "correct horse battery staple"
            )
        }
        #expect(ark.bitCount == 256)
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

private func withCoordinatorDependencies<R>(
    metadataStore: AccountMetadataStore,
    attemptTracker: RecoveryAttemptTracker,
    operation: () throws -> R
) rethrows -> R {
    try withDependencies {
        $0.accountMetadata = metadataStore.client
        $0.recoveryAttemptTracker = attemptTracker.client
    } operation: {
        try operation()
    }
}
