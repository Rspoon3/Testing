import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Detail view for displaying a single credential and its secrets.
public struct CredentialDetailView: View {

    @State private var viewModel: CredentialDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingManageSecrets = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializer

    /// Creates a new credential detail view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: CredentialDetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        List {
            headerSection
            secretsSection
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
            EditCredentialView(
                viewModel: EditCredentialViewModel(
                    credential: viewModel.key,
                    credentialManager: viewModel.credentialManager
                )
            )
        }
        .alert("Delete Credential", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteKey()
            }
        } message: {
            Text("Are you sure you want to delete '\(viewModel.key.label)'? This action cannot be undone.")
        }
        .navigationDestination(isPresented: $showingManageSecrets) {
            ManageSecretsView(
                viewModel: ManageSecretsViewModel(
                    credential: viewModel.key,
                    credentialManager: viewModel.credentialManager
                )
            )
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

    private var secretsSection: some View {
        Section {
            if viewModel.secrets.isEmpty {
                Text("No secrets found")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.secrets) { secret in
                    VStack(alignment: .leading, spacing: 12) {
                        // Secret label
                        Text(secret.secretLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Secret value with visibility toggle
                        HStack(spacing: 8) {
                            if viewModel.secretVisibility[secret.id] == true {
                                if let value = viewModel.decryptedSecrets[secret.id] {
                                    Text(value)
                                        .font(.body.monospaced())
                                        .textSelection(.enabled)
                                } else {
                                    ProgressView()
                                }
                            } else {
                                Text(String(repeating: "•", count: 16))
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                Task {
                                    await viewModel.toggleSecretVisibility(secret.id)
                                }
                            } label: {
                                Image(systemName: viewModel.secretVisibility[secret.id] == true ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }

                        // Copy button
                        Button {
                            Task {
                                await viewModel.copySecret(secret)
                            }
                        } label: {
                            HStack {
                                Label("Copy \(secret.secretLabel)", systemImage: "doc.on.doc")

                                Spacer()

                                if viewModel.showingCopyConfirmation == secret.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.green)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            HStack {
                Text("Secrets")
                Spacer()
                Button("See More") {
                    showingManageSecrets = true
                }
                .font(.subheadline)
                .textCase(nil)
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
        .animation(.default, value: viewModel.key)
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Credential", systemImage: "trash")
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
    let keychain = KeychainService()
    let vm = VaultManager(encryption: enc, keychain: keychain)
    let cm = CredentialManager(encryption: enc, vaultManager: vm)

    return NavigationStack {
        CredentialDetailView(
            viewModel: CredentialDetailViewModel(
                key: Credential(
                    label: "GitHub API Token",
                    websiteDomain: "github.com",
                    company: "GitHub",
                    environment: .production,
                    tags: ["git", "vcs"],
                    notes: "Production credential for CI/CD",
                    vaultID: UUID()
                ),
                credentialManager: cm
            )
        )
    }
}
