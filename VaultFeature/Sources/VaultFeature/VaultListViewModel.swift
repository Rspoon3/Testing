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

    @ObservationIgnored @FetchAll(Vault.none) var vaults: [Vault]

    public var pinnedVaults: [Vault] {
        vaults.filter(\.isPinned).sorted { $0.createdAt > $1.createdAt }
    }

    public var unpinnedVaults: [Vault] {
        vaults.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }
    }

    public var showingCreateSheet = false
    public var searchText = "" {
        didSet {
            if oldValue != searchText {
                updateQuery()
            }
        }
    }
    public var searchTask: Task<Void, Never>?

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

    /// Updates the vault query based on current search text.
    public func updateQuery() {
        searchTask?.cancel()
        searchTask = Task {
            await withErrorReporting {
                if searchText.isEmpty {
                    try await $vaults.load(
                        Vault.order { $0.createdAt.desc() },
                        animation: .default
                    )
                } else {
                    try await $vaults.load(
                        Vault
                            .where { $0.name.contains(searchText) }
                            .order { $0.createdAt.desc() },
                        animation: .default
                    )
                }
            }
        }
    }

    /// Toggles the pinned state of a vault.
    ///
    /// - Parameter vault: The vault to toggle.
    public func togglePin(for vault: Vault) async {
        var updatedVault = vault
        updatedVault.isPinned.toggle()
        await withErrorReporting {
            try await vaultManager.updateVault(updatedVault)
        }
    }

    /// Deletes a vault.
    ///
    /// - Parameter vault: The vault to delete.
    public func deleteVault(_ vault: Vault) async {
        await withErrorReporting {
            try await vaultManager.deleteVault(vault)
        }
    }

    /// Returns the API key manager for navigation.
    public func getAPIKeyManager() -> APIKeyManager {
        apiKeyManager
    }
}
