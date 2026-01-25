import Foundation
import TestDriveCore
import TestDrivePersistence

/// View model for the vault list screen.
///
/// Manages vault loading, creation, and deletion operations.
@MainActor
@Observable
public final class VaultListViewModel {

    public var vaults: [Vault] = []
    public var isLoading = false
    public var errorMessage: String?
    public var keyCounts: [UUID: Int] = [:]

    public let vaultManager: VaultManager
    public let apiKeyManager: APIKeyManager
    public let database: DatabaseManager

    // MARK: - Initializer

    /// Creates a new vault list view model.
    ///
    /// - Parameters:
    ///   - vaultManager: The vault manager for vault operations.
    ///   - apiKeyManager: The API key manager for key counts.
    ///   - database: The database manager for sync status.
    public init(
        vaultManager: VaultManager,
        apiKeyManager: APIKeyManager,
        database: DatabaseManager
    ) {
        self.vaultManager = vaultManager
        self.apiKeyManager = apiKeyManager
        self.database = database
    }

    // MARK: - Public Helpers

    /// Loads all vaults from the database.
    public func loadVaults() async {
        isLoading = true
        errorMessage = nil

        do {
            vaults = try await vaultManager.fetchAllVaults()
            await loadKeyCounts()

            // Trigger sync with CloudKit
            try? await database.startSync()
        } catch {
            errorMessage = "Failed to load vaults: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Creates a new vault.
    ///
    /// - Parameters:
    ///   - name: Vault name.
    ///   - iconName: SF Symbol name.
    ///   - colorHex: Hex color string.
    public func createVault(
        name: String,
        iconName: String,
        colorHex: String
    ) async throws {
        let vault = try await vaultManager.createVault(
            name: name,
            iconName: iconName,
            colorHex: colorHex
        )

        vaults.append(vault)
        keyCounts[vault.id] = 0
    }

    /// Deletes a vault.
    ///
    /// - Parameter vault: The vault to delete.
    public func deleteVault(_ vault: Vault) async throws {
        try await vaultManager.deleteVault(vault)
        vaults.removeAll { $0.id == vault.id }
        keyCounts.removeValue(forKey: vault.id)
    }

    // MARK: - Private Helpers

    /// Loads key counts for all vaults.
    private func loadKeyCounts() async {
        let vaultIDs = vaults.map(\.id)

        do {
            keyCounts = try await apiKeyManager.keyCounts(for: vaultIDs)
        } catch {
            // Silent failure for counts
        }
    }
}
