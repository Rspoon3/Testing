import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Key list screen for a specific vault.
///
/// Displays all API keys with search functionality and swipe actions.
public struct KeyListView: View {

    @State private var viewModel: KeyListViewModel
    @State private var showingAddSheet = false
    @State private var selectedKey: APIKey?

    // MARK: - Initializer

    /// Creates a new key list view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: KeyListViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.filteredKeys.isEmpty {
                if viewModel.searchText.isEmpty {
                    EmptyKeysView()
                } else {
                    noResultsView
                }
            } else {
                keyList
            }
        }
        .navigationTitle("Keys")
        .searchable(text: $viewModel.searchText, prompt: "Search keys")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadKeys()
        }
        .refreshable {
            await viewModel.loadKeys()
        }
    }

    // MARK: - Private Views

    private var keyList: some View {
        List {
            ForEach(viewModel.filteredKeys) { key in
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
                .swipeActions(edge: .leading) {
                    Button {
                        copySecret(key)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
            }
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
        .sheet(isPresented: $showingAddSheet) {
            EditKeyView(
                viewModel: EditKeyViewModel(
                    vaultID: viewModel.vault.id,
                    apiKeyManager: viewModel.apiKeyManager
                )
            )
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
}

#Preview {
    NavigationStack {
        KeyListView(
            viewModel: KeyListViewModel(
                vault: Vault(
                    name: "Test Vault",
                    iconName: "lock.fill",
                    colorHex: "#007AFF",
                    ownerPublicKey: Data()
                ),
                apiKeyManager: APIKeyManager(
                    database: try! DatabaseManager(enableSync: false),
                    encryption: EncryptionService(),
                    vaultManager: VaultManager(
                        database: try! DatabaseManager(enableSync: false),
                        encryption: EncryptionService(),
                        keychain: KeychainService()
                    )
                ),
                clipboardManager: ClipboardManager()
            )
        )
    }
}
