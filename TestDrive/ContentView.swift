import SwiftUI

struct ContentView: View {
    var session: EncryptionSession
    @State private var demoOutput = ""
    @State private var unlockError: String?

    // MARK: - Body

    var body: some View {
        if session.isUnlocked {
            unlockedView
        } else {
            lockedView
        }
    }

    // MARK: - Private Views

    private var unlockedView: some View {
        VStack {
            Text("SQLiteData Envelope Encryption")
                .font(.headline)
            Text(demoOutput)
                .font(.footnote.monospaced())
                .multilineTextAlignment(.center)
        }
        .padding()
        .task {
            guard let store = session.store else { return }
            do {
                let databaseURL = try EnvelopePaths.defaultDatabaseURL()
                print("Database: \(databaseURL.path)")

                let vaultID = try store.createVault(name: "Main Vault")
                let credentialID = try store.createCredential(vaultID: vaultID, label: "Stripe Prod")
                let secretID = try store.addSecret(
                    credentialID: credentialID,
                    name: "apiKey",
                    plaintext: Data("sk_live_demo".utf8)
                )
                let revealed = try store.revealSecret(secretID: secretID)

                let softwareLicenseID = try store.createSoftwareLicense(
                    vaultID: vaultID,
                    title: "Xcode Cloud Team Plan",
                    publisher: "Apple",
                    productName: "Xcode Cloud"
                )
                let softwareLicenseFieldID = try store.addSoftwareLicenseField(
                    itemID: softwareLicenseID,
                    fieldName: "licenseKey",
                    plaintext: Data("LICENSE-APPLE-DEMO-1234".utf8)
                )
                let revealedLicense = try store.revealSoftwareLicenseField(fieldID: softwareLicenseFieldID)

                let usernamePasswordID = try store.createUsernamePassword(
                    vaultID: vaultID,
                    title: "GitHub Login",
                    service: "GitHub",
                    loginURL: "https://github.com/login"
                )
                let usernameFieldID = try store.addUsernamePasswordField(
                    itemID: usernamePasswordID,
                    fieldName: "username",
                    plaintext: Data("dev@example.com".utf8)
                )
                let passwordFieldID = try store.addUsernamePasswordField(
                    itemID: usernamePasswordID,
                    fieldName: "password",
                    plaintext: Data("super-secret-password".utf8)
                )
                let revealedUsername = try store.revealUsernamePasswordField(fieldID: usernameFieldID)
                let revealedPassword = try store.revealUsernamePasswordField(fieldID: passwordFieldID)

                let patID = try store.createPersonalAccessToken(
                    vaultID: vaultID,
                    title: "GitHub PAT",
                    provider: "GitHub",
                    tokenName: "CI Token",
                    scopesHint: "repo, workflow"
                )
                let patFieldID = try store.addPersonalAccessTokenField(
                    itemID: patID,
                    fieldName: "token",
                    plaintext: Data("ghp_demo_personal_access_token".utf8)
                )
                let revealedPAT = try store.revealPersonalAccessTokenField(fieldID: patFieldID)

                let databaseCredentialID = try store.createDatabaseCredential(
                    vaultID: vaultID,
                    title: "Prod Postgres",
                    engine: "postgres",
                    host: "db.example.com",
                    port: 5432,
                    databaseName: "app_prod"
                )
                let databasePasswordFieldID = try store.addDatabaseCredentialField(
                    itemID: databaseCredentialID,
                    fieldName: "password",
                    plaintext: Data("postgres-password-demo".utf8)
                )
                let revealedDatabasePassword = try store.revealDatabaseCredentialField(
                    fieldID: databasePasswordFieldID
                )

                let signingID = try store.createMobileReleaseSigning(
                    vaultID: vaultID,
                    title: "iOS App Store Signing",
                    platform: "iOS",
                    appIdentifier: "com.example.app",
                    teamOrOrgIdentifier: "ABCDE12345"
                )
                let signingFieldID = try store.addMobileReleaseSigningField(
                    itemID: signingID,
                    fieldName: "p8Key",
                    plaintext: Data("-----BEGIN PRIVATE KEY-----demo-----END PRIVATE KEY-----".utf8)
                )
                let revealedSigning = try store.revealMobileReleaseSigningField(fieldID: signingFieldID)

                demoOutput = [
                    "Decrypted secret: \(String(decoding: revealed, as: UTF8.self))",
                    "Decrypted license: \(String(decoding: revealedLicense, as: UTF8.self))",
                    "Username: \(String(decoding: revealedUsername, as: UTF8.self))",
                    "Password: \(String(decoding: revealedPassword, as: UTF8.self))",
                    "PAT: \(String(decoding: revealedPAT, as: UTF8.self))",
                    "DB password: \(String(decoding: revealedDatabasePassword, as: UTF8.self))",
                    "Signing key: \(String(decoding: revealedSigning, as: UTF8.self))"
                ]
                .joined(separator: "\n")
            } catch {
                demoOutput = "Demo failed: \(error)"
            }
        }
    }

    private var lockedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
            Text("Session Locked")
                .font(.headline)
            Text("Keys have been zeroed from memory.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                unlock()
            } label: {
                Text("Unlock")
            }
            .buttonStyle(.borderedProminent)

            if let unlockError {
                Text(unlockError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    // MARK: - Private Helpers

    private func unlock() {
        do {
            try session.unlock()
            unlockError = nil
            demoOutput = ""
        } catch {
            unlockError = "Unlock failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView(session: EncryptionSession())
}
