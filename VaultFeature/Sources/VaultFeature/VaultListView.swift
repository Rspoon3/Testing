import SwiftUI
import TestDriveCore
import TestDrivePersistence

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
                if !viewModel.vaultRows.pinnedRows.isEmpty {
                    Section {
                        ForEach(viewModel.vaultRows.pinnedRows) { row in
                            NavigationLink {
                                VaultDetailsView(
                                    viewModel: VaultDetailsViewModel(
                                        vault: row.vault,
                                        credentialManager: viewModel.getCredentialManager(),
                                        clipboardManager: ClipboardManager(),
                                        vaultManager: viewModel.getVaultManager()
                                    )
                                )
                            } label: {
                                VaultRowView(vault: row.vault, keyCount: row.keyCount)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteVault(row.vault)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                Button {
                                    Task {
                                        await viewModel.togglePin(for: row.vault)
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
                    ForEach(viewModel.vaultRows.unpinnedRows) { row in
                        NavigationLink {
                            VaultDetailsView(
                                viewModel: VaultDetailsViewModel(
                                    vault: row.vault,
                                    credentialManager: viewModel.getCredentialManager(),
                                    clipboardManager: ClipboardManager(),
                                    vaultManager: viewModel.getVaultManager()
                                )
                            )
                        } label: {
                            VaultRowView(vault: row.vault, keyCount: row.keyCount)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteVault(row.vault)
                                }
                            } label: {
                                Image(systemName: "trash")
                            }
                            Button {
                                Task {
                                    await viewModel.togglePin(for: row.vault)
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
                        viewModel.showCreateVault()
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Menu {
                            ForEach(VaultOrdering.allCases, id: \.self) { ordering in
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
            .sheet(item: $viewModel.vaultForm) { draft in
                VaultFormView(vault: draft, vaultManager: viewModel.vaultManager)
            }
        }
    }
}

#Preview {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vaultManager = VaultManager(encryption: enc, keychain: key)
    let credentialManager = CredentialManager(encryption: enc, vaultManager: vaultManager)
    let viewModel = VaultListViewModel(
        vaultManager: vaultManager,
        credentialManager: credentialManager
    )

    return VaultListView(viewModel: viewModel)
}
