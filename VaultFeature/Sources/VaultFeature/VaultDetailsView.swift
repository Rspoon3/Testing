import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Vault details screen showing all API keys in a vault.
///
/// Displays all API keys with search functionality and swipe actions.
public struct VaultDetailsView: View {

    @State private var viewModel: VaultDetailsViewModel
    @State private var showingAddSheet = false
    @State private var selectedKey: APIKey?

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
                    EmptyKeysView()
                } else {
                    noResultsView
                }
            } else {
                keyList
            }
        }
        .navigationTitle(viewModel.vault.name)
        .searchable(text: $viewModel.searchText, prompt: "Search keys")
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
        }
        .task {
            await viewModel.task()
        }
        .refreshable {
            await viewModel.task()
        }
        .sheet(item: $viewModel.vaultForm) { draft in
            VaultFormView(vault: draft, vaultManager: viewModel.vaultManager)
        }
        .sheet(isPresented: $showingAddSheet) {
            EditKeyView(
                viewModel: EditKeyViewModel(
                    vaultID: viewModel.vaultID,
                    apiKeyManager: viewModel.apiKeyManager
                )
            )
        }
        .navigationDestination(item: $selectedKey) { key in
            KeyDetailView(
                viewModel: KeyDetailViewModel(
                    key: key,
                    apiKeyManager: viewModel.apiKeyManager,
                    clipboardManager: viewModel.clipboardManager
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
                    Text("Pinned")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }

            Section {
                ForEach(viewModel.unpinnedKeys) { key in
                    keyRow(for: key, isPinned: false)
                }
            } header: {
                Text("Keys")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }
        }
    }

    private func keyRow(for key: APIKey, isPinned: Bool) -> some View {
        Button {
            selectedKey = key
        } label: {
            KeyRowView(key: key)
        }
        .buttonStyle(.plain)
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

    private func deleteKey(_ key: APIKey) {
        Task {
            try? await viewModel.deleteKey(key)
        }
    }

    private func copySecret(_ key: APIKey) {
        Task {
            try? await viewModel.copySecret(key)
        }
    }

    private func togglePin(_ key: APIKey) {
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
    let akm = APIKeyManager(encryption: enc, vaultManager: vm)

    return NavigationStack {
        VaultDetailsView(
            viewModel: VaultDetailsViewModel(
                vault: Vault(
                    name: "Test Vault",
                    iconName: "lock.fill",
                    colorHex: "#007AFF",
                    ownerPublicKey: Data()
                ),
                apiKeyManager: akm,
                clipboardManager: ClipboardManager(),
                vaultManager: vm
            )
        )
    }
}
