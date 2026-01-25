import Foundation
import SQLiteData
import TestDriveCore
import TestDrivePersistence

/// View model for the key list screen.
///
/// Manages API key loading, searching, and deletion within a vault.
@MainActor
@Observable
public final class KeyListViewModel {

    @ObservationIgnored @FetchAll(APIKey.none)
    public var keys: [APIKey]

    @ObservationIgnored @FetchOne
    public var vault: Vault

    public var searchText = ""
    public var errorMessage: String?
    public var isLoading = false
    public var vaultForm: Vault.Draft?

    public let vaultID: UUID
    public let apiKeyManager: APIKeyManager
    public let clipboardManager: ClipboardManager
    public let vaultManager: VaultManager

    /// Filtered keys based on search text.
    public var filteredKeys: [APIKey] {
        if searchText.isEmpty {
            return keys
        }

        let lowercased = searchText.lowercased()
        return keys.filter { key in
            key.label.lowercased().contains(lowercased) ||
            key.websiteDomain?.lowercased().contains(lowercased) == true ||
            key.company?.lowercased().contains(lowercased) == true ||
            key.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }

    // MARK: - Initializer

    /// Creates a new key list view model.
    ///
    /// - Parameters:
    ///   - vault: The vault to display keys from.
    ///   - apiKeyManager: The API key manager.
    ///   - clipboardManager: The clipboard manager.
    ///   - vaultManager: The vault manager.
    public init(
        vault: Vault,
        apiKeyManager: APIKeyManager,
        clipboardManager: ClipboardManager,
        vaultManager: VaultManager
    ) {
        self.vault = vault
        self.vaultID = vault.id
        self.apiKeyManager = apiKeyManager
        self.clipboardManager = clipboardManager
        self.vaultManager = vaultManager
    }

    // MARK: - Public Helpers

    /// Main task called when view appears.
    public func task() async {
        await loadVault()
        await loadKeys()
    }

    /// Loads the vault from database to observe changes.
    private func loadVault() async {
        await withErrorReporting {
            try await $vault.load(Vault.where { $0.id.eq(vaultID) }, animation: .default)
        }
    }

    /// Loads all keys in the vault.
    private func loadKeys() async {
        isLoading = true
        errorMessage = nil

        await withErrorReporting {
            try await $keys.load(APIKey.where { $0.vaultID.eq(vaultID) }, animation: .default)
        }

        isLoading = false
    }

    /// Deletes an API key.
    ///
    /// - Parameter key: The key to delete.
    public func deleteKey(_ key: APIKey) async throws {
        try await apiKeyManager.deleteKey(key)
        // @FetchAll automatically updates keys array
    }

    /// Copies a key's secret to the clipboard.
    ///
    /// - Parameter key: The key whose secret to copy.
    public func copySecret(_ key: APIKey) async throws {
        let secret = try await apiKeyManager.getSecret(for: key)
        clipboardManager.copy(secret, label: key.label, keyID: key.id)

        // Mark key as used
        try await apiKeyManager.markAsUsed(key)
        // @FetchAll automatically updates keys array
    }

    /// Shows the vault configuration screen.
    public func showVaultConfiguration() {
        vaultForm = Vault.Draft(vault)
    }
}
