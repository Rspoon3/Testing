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

    @ObservationIgnored
    @FetchAll(VaultRow.where(\.isPinned), animation: .default)
    var pinnedVaultRows: [VaultRow]

    @ObservationIgnored
    @FetchAll(VaultRow.where { !$0.isPinned }, animation: .default)
    var unpinnedVaultRows: [VaultRow]

    public var pinnedVaults: [Vault] {
        pinnedVaultRows.map(\.vault)
    }

    public var unpinnedVaults: [Vault] {
        unpinnedVaultRows.map(\.vault)
    }

    public var vaultForm: Vault.Draft?
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
        // Views are automatically loaded, no manual loading needed
    }

    /// Updates the vault query based on current search text.
    public func updateQuery() {
        let searchText = self.searchText
        
        searchTask?.cancel()
        searchTask = Task {
            await withErrorReporting {
                if searchText.isEmpty {
                    async let pinnedTask = $pinnedVaultRows.load(
                        VaultRow.where(\.isPinned),
                        animation: .default
                    )

                    async let unpinnedTask = $unpinnedVaultRows.load(
                        VaultRow.where { !$0.isPinned },
                        animation: .default
                    )

                    _ = try await (pinnedTask.task, unpinnedTask.task)
                } else {
                    async let pinnedTask = $pinnedVaultRows.load(
                        VaultRow.where { $0.vault.name.contains(searchText) && $0.isPinned },
                        animation: .default
                    )

                    async let unpinnedTask = $unpinnedVaultRows.load(
                        VaultRow.where { $0.vault.name.contains(searchText) && !$0.isPinned },
                        animation: .default
                    )

                    _ = try await (pinnedTask.task, unpinnedTask.task)
                }
            }
        }
    }

    /// Toggles the pinned state of a vault.
    ///
    /// - Parameter vault: The vault to toggle.
    public func togglePin(for vault: Vault) async {
        await withErrorReporting {
            try await vaultManager.toggleVaultPin(vault)
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

    /// Returns the vault manager for navigation.
    public func getVaultManager() -> VaultManager {
        vaultManager
    }

    /// Shows the create vault form.
    public func showCreateVault() {
        vaultForm = Vault.Draft(
            id: nil,
            name: "",
            iconName: "lock.fill",
            colorHex: "#007AFF",
            sortOrder: 0,
            isDefault: false,
            createdAt: Date(),
            updatedAt: Date(),
            ownerPublicKey: Data(),
            ckRecordID: nil,
            ckShareID: nil,
            isShared: false,
            ownerUserID: nil
        )
    }
}
