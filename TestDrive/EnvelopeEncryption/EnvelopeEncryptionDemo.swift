import CryptoKit
import Foundation
import LocalAuthentication

/// End-to-end architecture walkthrough that exercises:
/// - account bootstrap
/// - device unlock
/// - recovery unlock
/// - sync unlock
/// - envelope encryption/decryption over SQLite
enum EnvelopeEncryptionDemo {
    /// Creates and unlocks the primary envelope store (bootstrap + device unlock).
    ///
    /// This is the first half of `run()` extracted so `EncryptionSession` can
    /// re-create a store without running the full demo.
    static func createPrimaryStore() throws -> EnvelopeStore {
        let recoveryCode = "correct horse battery staple"
        let databaseURL = try EnvelopePaths.defaultDatabaseURL()
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        let metadataStore = AccountMetadataStore(database: database)

        let accountID = try metadataStore.loadFirstRootWraps()?.accountID ?? UUID()
        let primaryEnrollment = try metadataStore.loadFirstDeviceEnrollment(accountID: accountID)
        let deviceAID = primaryEnrollment?.deviceID ?? UUID()
        let deviceAPolicy = KeychainWrapKeyStore.DeviceAccessPolicy.biometricDefault(
            prompt: "Authenticate to unlock this device's root encryption key."
        )
        let deviceAWrapKey = try KeychainWrapKeyStore.loadOrCreateDeviceWrapKey(
            accountID: accountID,
            deviceID: deviceAID,
            policy: deviceAPolicy
        )
        let syncWrapKey = try KeychainWrapKeyStore.loadOrCreateSyncWrapKey(accountID: accountID)

        if try metadataStore.loadFirstRootWraps() == nil {
            _ = try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: recoveryCode,
                initialDeviceID: deviceAID,
                initialDeviceWrapKey: deviceAWrapKey,
                metadataStore: metadataStore,
                syncWrapKey: syncWrapKey
            )
        }

        let ark: SymmetricKey
        do {
            ark = try AccountKeyCoordinator.unlockARKForDevice(
                metadataStore: metadataStore,
                accountID: accountID,
                deviceID: deviceAID,
                deviceWrapKey: deviceAWrapKey
            )
        } catch {
            let recoveredARK = try AccountKeyCoordinator.recoverARK(
                metadataStore: metadataStore,
                accountID: accountID,
                recoveryCode: recoveryCode
            )
            _ = try AccountKeyCoordinator.enrollDevice(
                metadataStore: metadataStore,
                accountID: accountID,
                ark: recoveredARK,
                deviceID: deviceAID,
                deviceWrapKey: deviceAWrapKey
            )
            ark = recoveredARK
        }

        return EnvelopeStore(database: database, ark: ark)
    }

    /// Runs the demo and returns the revealed secret string.
    static func run() throws -> String {
        let recoveryCode = "correct horse battery staple"
        let databaseURL = try EnvelopePaths.defaultDatabaseURL()
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        let metadataStore = AccountMetadataStore(database: database)

        let accountID = try metadataStore.loadFirstRootWraps()?.accountID ?? UUID()
        let primaryEnrollment = try metadataStore.loadFirstDeviceEnrollment(accountID: accountID)
        let deviceAID = primaryEnrollment?.deviceID ?? UUID()
        let deviceAPolicy = KeychainWrapKeyStore.DeviceAccessPolicy.biometricDefault(
            prompt: "Authenticate to unlock this device's root encryption key."
        )
        let deviceAWrapKey = try KeychainWrapKeyStore.loadOrCreateDeviceWrapKey(
            accountID: accountID,
            deviceID: deviceAID,
            policy: deviceAPolicy
        )
        let syncWrapKey = try KeychainWrapKeyStore.loadOrCreateSyncWrapKey(accountID: accountID)

        if try metadataStore.loadFirstRootWraps() == nil {
            _ = try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: recoveryCode,
                initialDeviceID: deviceAID,
                initialDeviceWrapKey: deviceAWrapKey,
                metadataStore: metadataStore,
                syncWrapKey: syncWrapKey
            )
        }

        let arkOnDeviceA: SymmetricKey
        do {
            arkOnDeviceA = try AccountKeyCoordinator.unlockARKForDevice(
                metadataStore: metadataStore,
                accountID: accountID,
                deviceID: deviceAID,
                deviceWrapKey: deviceAWrapKey
            )
        } catch {
            let recoveredARK = try AccountKeyCoordinator.recoverARK(
                metadataStore: metadataStore,
                accountID: accountID,
                recoveryCode: recoveryCode
            )
            _ = try AccountKeyCoordinator.enrollDevice(
                metadataStore: metadataStore,
                accountID: accountID,
                ark: recoveredARK,
                deviceID: deviceAID,
                deviceWrapKey: deviceAWrapKey
            )
            arkOnDeviceA = recoveredARK
        }

        let deviceAStore = EnvelopeStore(database: database, ark: arkOnDeviceA)

        let vaultID = try deviceAStore.createVault(name: "Main Vault")
        let credentialID = try deviceAStore.createCredential(vaultID: vaultID, label: "Stripe Prod")
        let secretID = try deviceAStore.addSecret(
            credentialID: credentialID,
            name: "apiKey",
            plaintext: Data("sk_live_demo".utf8)
        )

        let recoveredARK = try AccountKeyCoordinator.recoverARK(
            metadataStore: metadataStore,
            accountID: accountID,
            recoveryCode: recoveryCode
        )

        let deviceBID = UUID()
        let deviceBPolicy = KeychainWrapKeyStore.DeviceAccessPolicy.biometricDefault(
            prompt: "Authenticate to enroll and unlock a second trusted device key."
        )
        let deviceBWrapKey = try KeychainWrapKeyStore.loadOrCreateDeviceWrapKey(
            accountID: accountID,
            deviceID: deviceBID,
            policy: deviceBPolicy
        )
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
        let revealed = try deviceBStore.revealSecret(secretID: secretID)

        _ = try AccountKeyCoordinator.unlockARKFromSync(
            metadataStore: metadataStore,
            accountID: accountID,
            syncWrapKey: syncWrapKey
        )

        return String(decoding: revealed, as: UTF8.self)
    }
}
