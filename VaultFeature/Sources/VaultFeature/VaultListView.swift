import SwiftUI
import TestDriveCore
import TestDrivePersistence
import KeyFeature

/// Main vault list screen.
///
/// Displays all vaults with key counts and provides vault creation.
public struct VaultListView: View {

    @State private var viewModel: VaultListViewModel
    @State private var showingCreateSheet = false
    @State private var vaultToShare: Vault?

    // MARK: - Initializer

    /// Creates a new vault list view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: VaultListViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading vaults...")
                        .transition(.opacity)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        retryAction: {
                            Task {
                                await viewModel.loadVaults()
                            }
                        }
                    )
                    .transition(.opacity)
                } else if viewModel.vaults.isEmpty {
                    EmptyVaultsView()
                        .transition(.opacity)
                } else {
                    vaultList
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.2), value: viewModel.vaults.isEmpty)
            .navigationTitle("Vaults")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    SyncStatusView(database: viewModel.database)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateVaultSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadVaults()
            }
            .refreshable {
                await viewModel.loadVaults()
            }
        }
    }

    // MARK: - Private Views

    private var vaultList: some View {
        List {
            ForEach(viewModel.vaults) { vault in
                NavigationLink {
                    KeyListView(
                        viewModel: KeyListViewModel(
                            vault: vault,
                            apiKeyManager: viewModel.apiKeyManager,
                            clipboardManager: ClipboardManager()
                        )
                    )
                } label: {
                    VaultRowView(
                        vault: vault,
                        keyCount: viewModel.keyCounts[vault.id] ?? 0
                    )
                }
                .swipeActions(edge: .leading) {
                    Button {
                        vaultToShare = vault
                    } label: {
                        Label("Share", systemImage: "person.2")
                    }
                    .tint(.blue)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            .onDelete(perform: deleteVaults)
        }
        .listStyle(.insetGrouped)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.vaults)
        .sheet(item: $vaultToShare) { vault in
            ShareVaultView(
                viewModel: ShareVaultViewModel(
                    vault: vault,
                    vaultManager: viewModel.vaultManager,
                    database: viewModel.database
                )
            )
        }
    }

    // MARK: - Private Helpers

    private func deleteVaults(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let vault = viewModel.vaults[index]
                try? await viewModel.deleteVault(vault)
            }
        }
    }
}

#Preview {
    let db = try! DatabaseManager(enableSync: false)
    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(database: db, encryption: enc, keychain: key)
    let akm = APIKeyManager(database: db, encryption: enc, vaultManager: vm)

    return VaultListView(
        viewModel: VaultListViewModel(
            vaultManager: vm,
            apiKeyManager: akm,
            database: db
        )
    )
}
