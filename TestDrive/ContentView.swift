import SwiftUI

struct ContentView: View {
    var session: EncryptionSession
    @State private var unlockError: String?
    @State private var loadError: String?
    @State private var credentialSummaries: [EnvelopeStore.CredentialSummary] = []

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
        Group {
            if let store = session.store {
                NavigationStack {
                    List {
                        if let loadError {
                            Section("Load Error") {
                                Text(loadError)
                                    .foregroundStyle(.red)
                            }
                        }

                        Section("Credential Examples") {
                            ForEach(credentialSummaries) { summary in
                                NavigationLink {
                                    CredentialDetailView(store: store, credentialID: summary.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(summary.label)
                                        Text(summary.type.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Credential Catalog")
                }
            } else {
                ProgressView("Unlocking...")
            }
        }
        .task(id: session.isUnlocked) {
            guard let store = session.store else { return }
            do {
                let databaseURL = try EnvelopePaths.defaultDatabaseURL()
                print("Database: \(databaseURL.path)")
                credentialSummaries = try store.ensureDemoCredentialCatalog()
                loadError = nil
            } catch {
                credentialSummaries = []
                loadError = "Failed to load demo credentials: \(error)"
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
            loadError = nil
        } catch {
            unlockError = "Unlock failed: \(error.localizedDescription)"
        }
    }
}

private struct CredentialDetailView: View {
    let store: EnvelopeStore
    let credentialID: Credential.ID

    @State private var detail: EnvelopeStore.CredentialDetail?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            if let detail {
                Section("Credential") {
                    LabeledContent("Label", value: detail.label)
                    LabeledContent("Type", value: detail.type.rawValue)
                }

                Section("Secret Fields") {
                    ForEach(detail.secretFields) { secret in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(secret.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(secret.value)
                                .font(.body.monospaced())
                        }
                        .padding(.vertical, 2)
                    }
                }

                if !detail.attributes.isEmpty {
                    Section("Attributes") {
                        ForEach(detail.attributes) { attribute in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(attribute.kind.rawValue): \(attribute.name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(attribute.value)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if !detail.files.isEmpty {
                    Section("Files") {
                        ForEach(detail.files) { file in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.label)
                                    .font(.headline)
                                Text(file.fileName)
                                    .font(.caption.monospaced())
                                if let mimeType = file.mimeType {
                                    Text(mimeType)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Decrypted bytes: \(file.decryptedByteCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } else if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            } else {
                ProgressView("Loading credential…")
                
            }
        }
        .navigationTitle(detail?.label ?? "Credential")
        .task(id: credentialID) {
            do {
                detail = try store.loadCredentialDetail(credentialID: credentialID)
                errorMessage = nil
            } catch {
                detail = nil
                errorMessage = "Failed to load credential details: \(error)"
            }
        }
    }
}

#Preview {
    ContentView(session: EncryptionSession())
}
