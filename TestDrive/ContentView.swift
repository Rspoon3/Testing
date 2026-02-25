import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
                    credentialList(store: store)
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

    private func credentialList(store: EnvelopeStore) -> some View {
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
                        CredentialRow(summary: summary)
                    }
                }
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

// MARK: - CredentialRow

private struct CredentialRow: View {
    let summary: EnvelopeStore.CredentialSummary

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.label)
                Text(summary.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: summary.type.systemImage)
                .foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - CredentialDetailView

private struct CredentialDetailView: View {
    let store: EnvelopeStore
    let credentialID: Credential.ID

    @State private var detail: EnvelopeStore.CredentialDetail?
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        Form {
            if let detail {
                headerSection(detail)
                secretFieldsSection(detail)
                attributesSection(detail)
                filesSection(detail)
            } else if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            } else {
                ProgressView("Loading credential...")
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

    // MARK: - Private Views

    private func headerSection(_ detail: EnvelopeStore.CredentialDetail) -> some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.label)
                        .font(.headline)
                    Text(detail.type.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: detail.type.systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private func secretFieldsSection(_ detail: EnvelopeStore.CredentialDetail) -> some View {
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
    }

    @ViewBuilder
    private func attributesSection(_ detail: EnvelopeStore.CredentialDetail) -> some View {
        if !detail.attributes.isEmpty {
            Section("Attributes") {
                ForEach(detail.attributes) { attribute in
                    LabeledContent {
                        Text(attribute.value)
                    } label: {
                        Text(attribute.name)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func filesSection(_ detail: EnvelopeStore.CredentialDetail) -> some View {
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
                        if let previewImage = imagePreview(for: file) {
                            previewImage
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Text("Decrypted bytes: \(file.decryptedByteCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func imagePreview(for file: EnvelopeStore.CredentialFileDisplay) -> Image? {
        guard file.mimeType?.hasPrefix("image/") == true else { return nil }
        #if canImport(UIKit)
            guard let image = UIImage(data: file.decryptedData) else { return nil }
            return Image(uiImage: image)
        #elseif canImport(AppKit)
            guard let image = NSImage(data: file.decryptedData) else { return nil }
            return Image(nsImage: image)
        #else
            return nil
        #endif
    }
}

#Preview {
    ContentView(session: EncryptionSession())
}
