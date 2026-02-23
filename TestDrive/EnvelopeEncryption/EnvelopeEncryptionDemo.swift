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
        let softwareLicenseID = try deviceAStore.createSoftwareLicense(
            vaultID: vaultID,
            title: "Xcode Cloud Team Plan",
            publisher: "Apple",
            productName: "Xcode Cloud"
        )
        let softwareLicenseFieldID = try deviceAStore.addSoftwareLicenseField(
            itemID: softwareLicenseID,
            fieldName: "licenseKey",
            plaintext: Data("LICENSE-APPLE-DEMO-1234".utf8)
        )
        let usernamePasswordID = try deviceAStore.createUsernamePassword(
            vaultID: vaultID,
            title: "GitHub Login",
            service: "GitHub",
            loginURL: "https://github.com/login"
        )
        let usernameFieldID = try deviceAStore.addUsernamePasswordField(
            itemID: usernamePasswordID,
            fieldName: "username",
            plaintext: Data("dev@example.com".utf8)
        )
        let passwordFieldID = try deviceAStore.addUsernamePasswordField(
            itemID: usernamePasswordID,
            fieldName: "password",
            plaintext: Data("super-secret-password".utf8)
        )
        let patID = try deviceAStore.createPersonalAccessToken(
            vaultID: vaultID,
            title: "GitHub PAT",
            provider: "GitHub",
            tokenName: "CI Token",
            scopesHint: "repo, workflow"
        )
        let patFieldID = try deviceAStore.addPersonalAccessTokenField(
            itemID: patID,
            fieldName: "token",
            plaintext: Data("ghp_demo_personal_access_token".utf8)
        )
        let databaseCredentialID = try deviceAStore.createDatabaseCredential(
            vaultID: vaultID,
            title: "Prod Postgres",
            engine: "postgres",
            host: "db.example.com",
            port: 5432,
            databaseName: "app_prod"
        )
        let databasePasswordFieldID = try deviceAStore.addDatabaseCredentialField(
            itemID: databaseCredentialID,
            fieldName: "password",
            plaintext: Data("postgres-password-demo".utf8)
        )
        let signingID = try deviceAStore.createMobileReleaseSigning(
            vaultID: vaultID,
            title: "iOS App Store Signing",
            platform: "iOS",
            appIdentifier: "com.example.app",
            teamOrOrgIdentifier: "ABCDE12345"
        )
        let signingFieldID = try deviceAStore.addMobileReleaseSigningField(
            itemID: signingID,
            fieldName: "p8Key",
            plaintext: Data("-----BEGIN PRIVATE KEY-----demo-----END PRIVATE KEY-----".utf8)
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
        let revealedLicense = try deviceBStore.revealSoftwareLicenseField(fieldID: softwareLicenseFieldID)
        let revealedUsername = try deviceBStore.revealUsernamePasswordField(fieldID: usernameFieldID)
        let revealedPassword = try deviceBStore.revealUsernamePasswordField(fieldID: passwordFieldID)
        let revealedPAT = try deviceBStore.revealPersonalAccessTokenField(fieldID: patFieldID)
        let revealedDatabasePassword = try deviceBStore.revealDatabaseCredentialField(
            fieldID: databasePasswordFieldID
        )
        let revealedSigning = try deviceBStore.revealMobileReleaseSigningField(fieldID: signingFieldID)

        _ = try AccountKeyCoordinator.unlockARKFromSync(
            metadataStore: metadataStore,
            accountID: accountID,
            syncWrapKey: syncWrapKey
        )

        return [
            "apiKey=\(String(decoding: revealed, as: UTF8.self))",
            "licenseKey=\(String(decoding: revealedLicense, as: UTF8.self))",
            "username=\(String(decoding: revealedUsername, as: UTF8.self))",
            "password=\(String(decoding: revealedPassword, as: UTF8.self))",
            "pat=\(String(decoding: revealedPAT, as: UTF8.self))",
            "dbPassword=\(String(decoding: revealedDatabasePassword, as: UTF8.self))",
            "signingKey=\(String(decoding: revealedSigning, as: UTF8.self))"
        ]
        .joined(separator: ", ")
    }
}
