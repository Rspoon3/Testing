import CryptoKit
import Dependencies
import Foundation
import LocalAuthentication
import SQLiteData

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
        @Dependency(\.defaultDatabase) var database
        let recoveryCode = "correct horse battery staple"
        var metadataStore: AccountMetadataStore!
        var attemptTracker: RecoveryAttemptTracker!
        return try withDependencies {
            $0.defaultDatabase = database
            metadataStore = AccountMetadataStore()
            attemptTracker = RecoveryAttemptTracker()
            $0.accountMetadata = metadataStore.client
            $0.recoveryAttemptTracker = attemptTracker.client
        } operation: {
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
                    syncWrapKey: syncWrapKey
                )
            }

            let ark: SymmetricKey
            do {
                ark = try AccountKeyCoordinator.unlockARKForDevice(
                    accountID: accountID,
                    deviceID: deviceAID,
                    deviceWrapKey: deviceAWrapKey
                )
            } catch {
                let recoveredARK = try AccountKeyCoordinator.recoverARK(
                    accountID: accountID,
                    recoveryCode: recoveryCode
                )
                _ = try AccountKeyCoordinator.enrollDevice(
                    accountID: accountID,
                    ark: recoveredARK,
                    deviceID: deviceAID,
                    deviceWrapKey: deviceAWrapKey
                )
                ark = recoveredARK
            }

            return EnvelopeStore(
                ark: ark,
                arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
            )
        }
    }

    /// Runs the demo and returns the revealed secret string.
    static func run() throws -> String {
        @Dependency(\.defaultDatabase) var database
        let recoveryCode = "correct horse battery staple"
        var metadataStore: AccountMetadataStore!
        var attemptTracker: RecoveryAttemptTracker!
        return try withDependencies {
            $0.defaultDatabase = database
            metadataStore = AccountMetadataStore()
            attemptTracker = RecoveryAttemptTracker()
            $0.accountMetadata = metadataStore.client
            $0.recoveryAttemptTracker = attemptTracker.client
        } operation: {
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
                    syncWrapKey: syncWrapKey
                )
            }

            let arkOnDeviceA: SymmetricKey
            do {
                arkOnDeviceA = try AccountKeyCoordinator.unlockARKForDevice(
                    accountID: accountID,
                    deviceID: deviceAID,
                    deviceWrapKey: deviceAWrapKey
                )
            } catch {
                let recoveredARK = try AccountKeyCoordinator.recoverARK(
                    accountID: accountID,
                    recoveryCode: recoveryCode
                )
                _ = try AccountKeyCoordinator.enrollDevice(
                    accountID: accountID,
                    ark: recoveredARK,
                    deviceID: deviceAID,
                    deviceWrapKey: deviceAWrapKey
                )
                arkOnDeviceA = recoveredARK
            }

            let deviceAStore = EnvelopeStore(
                ark: arkOnDeviceA,
                arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
            )

            let vaultID = try deviceAStore.createVault(name: "Main Vault")
            let apiCredential = try deviceAStore.createCredential(
                vaultID: vaultID,
                label: "Stripe Prod",
                type: .genericSecret,
                initialSecretLabel: "apiKey",
                initialSecretPlaintext: Data("sk_live_demo".utf8),
                environment: "production",
                links: ["https://dashboard.stripe.com"],
                associatedEmails: ["payments@example.com"],
                notes: "Primary payments key."
            )
            let softwareLicense = try deviceAStore.createCredential(
                vaultID: vaultID,
                label: "Xcode Cloud Team Plan",
                type: .softwareLicense,
                initialSecretLabel: "licenseKey",
                initialSecretPlaintext: Data("LICENSE-APPLE-DEMO-1234".utf8),
                links: ["https://developer.apple.com/xcode-cloud/"],
                associatedEmails: ["ios@example.com"]
            )
            let usernamePassword = try deviceAStore.createCredential(
                vaultID: vaultID,
                label: "GitHub Login",
                type: .usernamePassword,
                initialSecretLabel: "username",
                initialSecretPlaintext: Data("dev@example.com".utf8),
                links: ["https://github.com/login"]
            )
            let passwordFieldID = try deviceAStore.addSecret(
                credentialID: usernamePassword.credentialID,
                name: "password",
                plaintext: Data("super-secret-password".utf8)
            )
            let personalAccessToken = try deviceAStore.createCredential(
                vaultID: vaultID,
                label: "GitHub PAT",
                type: .personalAccessToken,
                initialSecretLabel: "token",
                initialSecretPlaintext: Data("ghp_demo_personal_access_token".utf8),
                notes: "Scopes: repo, workflow"
            )
            let databaseCredential = try deviceAStore.createCredential(
                vaultID: vaultID,
                label: "Prod Postgres",
                type: .databaseCredential,
                initialSecretLabel: "password",
                initialSecretPlaintext: Data("postgres-password-demo".utf8),
                environment: "production",
                links: ["postgres://db.example.com:5432/app_prod"]
            )
            let signingCredential = try deviceAStore.createCredential(
                vaultID: vaultID,
                label: "iOS App Store Signing",
                type: .mobileReleaseSigning,
                initialSecretLabel: "issuerID",
                initialSecretPlaintext: Data("00000000-0000-0000-0000-000000000000".utf8),
                associatedEmails: ["release@example.com"],
                notes: "Team ID: ABCDE12345, App ID: com.example.app"
            )
            let p8FileID = try deviceAStore.addSecretFile(
                credentialID: signingCredential.credentialID,
                label: "App Store Connect API Key",
                fileName: "AuthKey_ABC123DEFG.p8",
                mimeType: "application/x-pkcs8",
                plaintext: Data("-----BEGIN PRIVATE KEY-----demo-----END PRIVATE KEY-----".utf8)
            )

            let recoveredARK = try AccountKeyCoordinator.recoverARK(
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
                accountID: accountID,
                ark: recoveredARK,
                deviceID: deviceBID,
                deviceWrapKey: deviceBWrapKey
            )
            let arkOnDeviceB = try AccountKeyCoordinator.unlockARKForDevice(
                accountID: accountID,
                deviceID: deviceBID,
                deviceWrapKey: deviceBWrapKey
            )
            let deviceBStore = EnvelopeStore(
                ark: arkOnDeviceB,
                arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
            )
            let revealed = try deviceBStore.revealSecret(secretID: apiCredential.initialSecretFieldID)
            let revealedLicense = try deviceBStore.revealSecret(secretID: softwareLicense.initialSecretFieldID)
            let revealedUsername = try deviceBStore.revealSecret(secretID: usernamePassword.initialSecretFieldID)
            let revealedPassword = try deviceBStore.revealSecret(secretID: passwordFieldID)
            let revealedPAT = try deviceBStore.revealSecret(secretID: personalAccessToken.initialSecretFieldID)
            let revealedDatabasePassword = try deviceBStore.revealSecret(
                secretID: databaseCredential.initialSecretFieldID
            )
            let revealedIssuerID = try deviceBStore.revealSecret(secretID: signingCredential.initialSecretFieldID)
            let revealedP8File = try deviceBStore.revealSecretFile(fileID: p8FileID)

            _ = try AccountKeyCoordinator.unlockARKFromSync(
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
                "issuerID=\(String(decoding: revealedIssuerID, as: UTF8.self))",
                "p8Bytes=\(revealedP8File.count)"
            ]
            .joined(separator: ", ")
        }
    }
}
