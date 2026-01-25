import Foundation
import SQLiteData
import TestDriveCore
import TestDrivePersistence

/// View model for the vault details screen.
///
/// Manages API key loading, searching, and deletion within a vault.
@MainActor
@Observable
public final class VaultDetailsViewModel {

    @ObservationIgnored @FetchAll(APIKeyRow.none)
    private var keyRows: [APIKeyRow]

    @ObservationIgnored @FetchOne(Vault.none)
    private var observedVault: Vault?

    public var searchText = "" {
        didSet {
            if oldValue != searchText {
                updateQuery()
            }
        }
    }
    public var searchTask: Task<Void, Never>?
    public var errorMessage: String?
    public var isLoading = false
    public var vaultForm: Vault.Draft?

    /// The vault being displayed. Returns observed vault if loaded, otherwise initial vault.
    public var vault: Vault {
        observedVault ?? initialVault
    }

    /// Pinned keys filtered by search text.
    public var pinnedKeys: [APIKey] {
        filterKeys(keyRows.filter(\.isPinned).map(\.apiKey))
    }

    /// Unpinned keys filtered by search text.
    public var unpinnedKeys: [APIKey] {
        filterKeys(keyRows.filter { !$0.isPinned }.map(\.apiKey))
    }

    private let initialVault: Vault
    public let vaultID: UUID
    public let apiKeyManager: APIKeyManager
    public let clipboardManager: ClipboardManager
    public let vaultManager: VaultManager

    /// Filters keys based on search text.
    private func filterKeys(_ keys: [APIKey]) -> [APIKey] {
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

    /// Creates a new vault details view model.
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
        self.initialVault = vault
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
            try await $observedVault.load(Vault.where { $0.id.eq(vaultID) }, animation: .default)
        }
    }

    /// Loads all keys in the vault.
    private func loadKeys() async {
        isLoading = true
        errorMessage = nil

        await withErrorReporting {
            try await $keyRows.load(
                APIKeyRow.where { $0.apiKey.vaultID.eq(vaultID) },
                animation: .default
            )
        }

        isLoading = false
    }

    /// Updates the key query based on current search text.
    private func updateQuery() {
        let searchText = self.searchText

        searchTask?.cancel()
        searchTask = Task {
            await withErrorReporting {
                try await $keyRows.load(
                    APIKeyRow.where { $0.apiKey.vaultID.eq(vaultID) },
                    animation: .default
                )
            }
        }
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

    /// Toggles the pinned state of an API key.
    ///
    /// - Parameter key: The key to toggle.
    public func togglePin(for key: APIKey) async {
        await withErrorReporting {
            try await apiKeyManager.toggleKeyPin(key)
        }
    }

    /// Shows the vault configuration screen.
    public func showVaultConfiguration() {
        vaultForm = Vault.Draft(vault)
    }
}
