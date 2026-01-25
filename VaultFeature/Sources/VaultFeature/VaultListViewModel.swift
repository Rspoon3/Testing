import Foundation
import SQLiteData
import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// View model for the vault list screen.
///
/// Manages vault fetching, creation, and deletion operations.
@MainActor
@Observable
public final class VaultListViewModel {

    @ObservationIgnored @FetchAll var vaults: [Vault]
    public var showingCreateSheet = false

    public let vaultManager: VaultManager
    private let apiKeyManager: APIKeyManager

    // MARK: - Initializer

    /// Creates a new vault list view model.
    ///
    /// - Parameters:
    ///   - vaultManager: The vault manager for vault operations.
    ///   - apiKeyManager: The API key manager for key operations.
    public init(
        vaultManager: VaultManager,
        apiKeyManager: APIKeyManager
    ) {
        self.vaultManager = vaultManager
        self.apiKeyManager = apiKeyManager
    }

    // MARK: - Public Helpers

    /// Loads vaults from the database.
    public func loadVaults() async {
        await withErrorReporting {
            try await $vaults.load(
                Vault.order { $0.createdAt.desc() },
                animation: .default
            )
            .task
        }
    }
    
    /// Deletes vaults at the specified offsets.
    ///
    /// - Parameter offsets: The index set of vaults to delete.
    public func deleteVaults(at offsets: IndexSet) async {
        for index in offsets {
            let vault = vaults[index]
            await withErrorReporting {
                try await vaultManager.deleteVault(vault)
            }
        }
    }
    
    /// Returns the API key manager for navigation.
    public func getAPIKeyManager() -> APIKeyManager {
        apiKeyManager
    }
}
