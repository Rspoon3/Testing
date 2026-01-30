import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Detail view for a single API key.
///
/// Displays all metadata and provides secret viewing/copying functionality.
public struct KeyDetailView: View {

    @State private var viewModel: KeyDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializer

    /// Creates a new key detail view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: KeyDetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        List {
            headerSection
            secretSection
            metadataSection
            timestampsSection
            dangerSection
        }
        .navigationTitle(viewModel.key.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditKeyView(
                viewModel: EditKeyViewModel(
                    key: viewModel.key,
                    apiKeyManager: viewModel.apiKeyManager
                )
            )
        }
        .alert("Delete Key", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteKey()
            }
        } message: {
            Text("Are you sure you want to delete '\(viewModel.key.label)'? This action cannot be undone.")
        }
    }

    // MARK: - Private Views

    private var headerSection: some View {
        Section {
            HStack(spacing: 16) {
                if let domain = viewModel.key.websiteDomain {
                    DomainLogoView(domain: domain, size: 64)
                } else {
                    Image(systemName: "key.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .frame(width: 64, height: 64)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.key.label)
                        .font(.title3)
                        .fontWeight(.semibold)

                    if let domain = viewModel.key.websiteDomain {
                        Text(domain)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    private var secretSection: some View {
        Section("Secret") {
            SecretFieldView(
                secret: viewModel.secret,
                isVisible: viewModel.isSecretVisible,
                isLoading: viewModel.isLoading,
                onToggleVisibility: {
                    Task {
                        await viewModel.toggleSecretVisibility()
                    }
                }
            )

            Button {
                Task {
                    await viewModel.copySecret()
                }
            } label: {
                Label("Copy Secret", systemImage: "doc.on.doc")
            }
        }
    }

    private var metadataSection: some View {
        Section("Details") {
            if let domain = viewModel.key.websiteDomain {
                LabeledContent("Domain", value: domain)
            }

            if let company = viewModel.key.company {
                LabeledContent("Company", value: company)
            }

            LabeledContent("Environment") {
                Text(viewModel.key.environment.rawValue.capitalized)
                    .foregroundStyle(environmentColor)
            }

            if !viewModel.key.tags.isEmpty {
                LabeledContent("Tags") {
                    Text(viewModel.key.tags.joined(separator: ", "))
                }
            }

            if !viewModel.key.notes.isEmpty {
                LabeledContent("Notes") {
                    Text(viewModel.key.notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let rotateAt = viewModel.key.rotateAt {
                LabeledContent("Rotate At") {
                    HStack {
                        Text(rotateAt, style: .date)

                        if rotateAt <= Date() {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
    }

    private var timestampsSection: some View {
        Section("History") {
            LabeledContent("Created", value: viewModel.key.createdAt, format: .dateTime)

            if let lastUsed = viewModel.key.lastUsedAt {
                LabeledContent("Last Used", value: lastUsed, format: .dateTime)
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Key", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var environmentColor: Color {
        switch viewModel.key.environment {
        case .production:
            return .red
        case .staging:
            return .orange
        case .development:
            return .green
        case .testing:
            return .blue
        case .custom:
            return .purple
        }
    }

    // MARK: - Private Helpers

    private func deleteKey() {
        Task {
            try? await viewModel.deleteKey()
            dismiss()
        }
    }
}

#Preview {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(encryption: enc, keychain: key)
    let akm = APIKeyManager(encryption: enc, vaultManager: vm)

    return NavigationStack {
        KeyDetailView(
            viewModel: KeyDetailViewModel(
                key: APIKey(
                    label: "GitHub API Token",
                    websiteDomain: "github.com",
                    company: "GitHub",
                    environment: .production,
                    tags: ["git", "vcs"],
                    notes: "Production API key for CI/CD",
                    vaultID: UUID(),
                    encryptedSecret: Data(),
                    nonce: Data()
                ),
                apiKeyManager: akm,
                clipboardManager: ClipboardManager()
            )
        )
    }
}
