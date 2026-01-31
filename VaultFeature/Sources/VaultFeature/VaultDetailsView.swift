import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Vault details screen showing all credentials in a vault.
///
/// Displays all credentials with search functionality and swipe actions.
public struct VaultDetailsView: View {

    @State private var viewModel: VaultDetailsViewModel
    @State private var showingAddSheet = false

    // MARK: - Initializer

    /// Creates a new vault details view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: VaultDetailsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.pinnedKeys.isEmpty && viewModel.unpinnedKeys.isEmpty {
                if viewModel.searchText.isEmpty {
                    EmptyCredentialsView()
                } else {
                    noResultsView
                }
            } else {
                keyList
            }
        }
        .navigationTitle(viewModel.vault.name)
        .searchable(text: $viewModel.searchText, prompt: "Search credentials")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showVaultConfiguration()
                } label: {
                    Image(systemName: "info.circle")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Menu {
                        ForEach(CredentialOrdering.allCases, id: \.self) { ordering in
                            Button {
                                Task {
                                    await viewModel.orderingButtonTapped(ordering)
                                }
                            } label: {
                                Label {
                                    Text(ordering.rawValue)
                                } icon: {
                                    ordering.icon
                                }
                            }
                        }
                    } label: {
                        Label("Sort By", systemImage: "arrow.up.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await viewModel.task()
        }
        .sheet(item: $viewModel.vaultForm) { draft in
            VaultFormView(vault: draft, vaultManager: viewModel.vaultManager)
        }
        .sheet(isPresented: $showingAddSheet) {
            EditCredentialView(
                viewModel: EditCredentialViewModel(
                    vaultID: viewModel.vaultID,
                    credentialManager: viewModel.credentialManager
                )
            )
        }
    }

    // MARK: - Private Views

    private var keyList: some View {
        List {
            if !viewModel.pinnedKeys.isEmpty {
                Section {
                    ForEach(viewModel.pinnedKeys) { key in
                        keyRow(for: key, isPinned: true)
                    }
                } header: {
                    Text("Pinned Credentials")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
                .animation(.default, value: viewModel.pinnedKeys.map(\.id))
            }

            Section {
                ForEach(viewModel.unpinnedKeys) { key in
                    keyRow(for: key, isPinned: false)
                }
            } header: {
                Text("Credentials")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }
            .animation(.default, value: viewModel.unpinnedKeys.map(\.id))
        }
    }

    private func keyRow(for key: Credential, isPinned: Bool) -> some View {
        NavigationLink {
            CredentialDetailView(
                viewModel: CredentialDetailViewModel(
                    key: key,
                    credentialManager: viewModel.credentialManager,
                    clipboardManager: viewModel.clipboardManager
                )
            )
        } label: {
            CredentialRowView(key: key)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteKey(key)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                togglePin(key)
            } label: {
                Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading) {
            Button {
                copySecret(key)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }

    private var noResultsView: some View {
        ContentUnavailableView.search(text: viewModel.searchText)
    }

    // MARK: - Private Helpers

    private func deleteKey(_ key: Credential) {
        Task {
            try? await viewModel.deleteKey(key)
        }
    }

    private func copySecret(_ key: Credential) {
        Task {
            try? await viewModel.copySecret(key)
        }
    }

    private func togglePin(_ key: Credential) {
        Task {
            await viewModel.togglePin(for: key)
        }
    }
}

#Preview {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(encryption: enc, keychain: key)
    let akm = CredentialManager(encryption: enc, vaultManager: vm)

    return NavigationStack {
        VaultDetailsView(
            viewModel: VaultDetailsViewModel(
                vault: Vault(
                    name: "Test Vault",
                    iconName: "lock.fill",
                    colorHex: "#007AFF",
                    ownerPublicKey: Data()
                ),
                credentialManager: akm,
                clipboardManager: ClipboardManager(),
                vaultManager: vm
            )
        )
    }
}
