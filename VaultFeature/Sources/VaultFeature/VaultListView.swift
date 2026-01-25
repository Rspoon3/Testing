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
                ForEach(viewModel.vaults) { vault in
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
                }
                .onDelete { indexSet in
                    Task {
                        await viewModel.deleteVaults(at: indexSet)
                    }
                }
            }
            .navigationTitle("Vaults (\(viewModel.vaults.count))")
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
