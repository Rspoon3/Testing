import SwiftUI
import TestDriveCore
import TestDrivePersistence
import KeyFeature

/// Main vault list screen.
///
/// Displays all vaults with key counts and provides vault creation.
public struct VaultListView: View {

    @State private var viewModel: VaultListViewModel

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
            List {
                if !viewModel.pinnedVaults.isEmpty {
                    Section {
                        ForEach(viewModel.pinnedVaults) { vault in
                            NavigationLink {
                                KeyListView(
                                    viewModel: KeyListViewModel(
                                        vault: vault,
                                        apiKeyManager: viewModel.getAPIKeyManager(),
                                        clipboardManager: ClipboardManager()
                                    )
                                )
                            } label: {
                                VaultRowView(vault: vault, keyCount: 0)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteVault(vault)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                Button {
                                    Task {
                                        await viewModel.togglePin(for: vault)
                                    }
                                } label: {
                                    Image(systemName: "pin.slash")
                                }
                                .tint(.orange)
                            }
                        }
                    } header: {
                        Text("Pinned")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }

                Section {
                    ForEach(viewModel.unpinnedVaults) { vault in
                        NavigationLink {
                            KeyListView(
                                viewModel: KeyListViewModel(
                                    vault: vault,
                                    apiKeyManager: viewModel.getAPIKeyManager(),
                                    clipboardManager: ClipboardManager()
                                )
                            )
                        } label: {
                            VaultRowView(vault: vault, keyCount: 0)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteVault(vault)
                                }
                            } label: {
                                Image(systemName: "trash")
                            }
                            Button {
                                Task {
                                    await viewModel.togglePin(for: vault)
                                }
                            } label: {
                                Image(systemName: "pin")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    Text("Vaults")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
            .navigationTitle("Vaults")
            .searchable(text: $viewModel.searchText, prompt: "Search vaults")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateSheet) {
                CreateVaultSheet(vaultManager: viewModel.vaultManager)
            }
            .task {
                await viewModel.loadVaults()
            }
        }
    }
}

#Preview {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vaultManager = VaultManager(encryption: enc, keychain: key)
    let apiKeyManager = APIKeyManager(encryption: enc, vaultManager: vaultManager)
    let viewModel = VaultListViewModel(
        vaultManager: vaultManager,
        apiKeyManager: apiKeyManager
    )

    return VaultListView(viewModel: viewModel)
}
