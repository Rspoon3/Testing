import Foundation
import SQLiteData
import TestDriveCore
import TestDrivePersistence

/// View model for the vault list screen.
///
/// Manages vault loading, creation, and deletion operations.
@MainActor
@Observable
public final class VaultListViewModel {

    @ObservationIgnored @FetchAll(Vault.order(by: \.sortOrder))
    public var vaults: [Vault]

    public var errorMessage: String?
    public var keyCounts: [UUID: Int] = [:]
    public var isLoading = false

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
            try await $vaults.load(Vault.order(by: \.sortOrder))
            await updateKeyCounts()
        } catch {
            errorMessage = "Failed to load vaults: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Loads key counts for all vaults.
    public func loadKeyCounts() async {
        await updateKeyCounts()
    }

    /// Starts sync with CloudKit.
    public func startSync() async {
        try? await database.startSync()
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

        // @FetchAll automatically updates vaults array
        keyCounts[vault.id] = 0
    }

    /// Deletes a vault.
    ///
    /// - Parameter vault: The vault to delete.
    public func deleteVault(_ vault: Vault) async throws {
        try await vaultManager.deleteVault(vault)
        // @FetchAll automatically updates vaults array
        keyCounts.removeValue(forKey: vault.id)
    }

    // MARK: - Private Helpers

    /// Updates key counts for all vaults.
    private func updateKeyCounts() async {
        let vaultIDs = vaults.map(\.id)

        do {
            keyCounts = try await apiKeyManager.keyCounts(for: vaultIDs)
        } catch {
            // Silent failure for counts
        }
    }
}
