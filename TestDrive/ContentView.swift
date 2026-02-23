import SwiftUI

struct ContentView: View {
    var session: EncryptionSession
    @State private var demoOutput = ""
    @State private var databasePathOutput = ""
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
            Text(databasePathOutput)
                .font(.caption.monospaced())
                .multilineTextAlignment(.center)
            Text(demoOutput)
                .font(.footnote.monospaced())
                .multilineTextAlignment(.center)
        }
        .padding()
        .task {
            guard let store = session.store else { return }
            do {
                let databaseURL = try EnvelopePaths.defaultDatabaseURL()
                databasePathOutput = "Database: \(databaseURL.path)"

                let vaultID = try store.createVault(name: "Main Vault")
                let credentialID = try store.createCredential(vaultID: vaultID, label: "Stripe Prod")
                let secretID = try store.addSecret(
                    credentialID: credentialID,
                    name: "apiKey",
                    plaintext: Data("sk_live_demo".utf8)
                )
                let revealed = try store.revealSecret(secretID: secretID)
                demoOutput = "Decrypted secret: \(String(decoding: revealed, as: UTF8.self))"
            } catch {
                if databasePathOutput.isEmpty {
                    databasePathOutput = "Database path unavailable: \(error)"
                }
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
            databasePathOutput = ""
        } catch {
            unlockError = "Unlock failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView(session: EncryptionSession())
}
