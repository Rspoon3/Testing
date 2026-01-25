import Foundation
import TestDriveCore
import TestDrivePersistence

/// View model for the key list screen.
///
/// Manages API key loading, searching, and deletion within a vault.
@MainActor
@Observable
public final class KeyListViewModel {

    public var keys: [APIKey] = []
    public var searchText = ""
    public var isLoading = false
    public var errorMessage: String?

    public let vault: Vault
    public let apiKeyManager: APIKeyManager
    public let clipboardManager: ClipboardManager

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
    public init(
        vault: Vault,
        apiKeyManager: APIKeyManager,
        clipboardManager: ClipboardManager
    ) {
        self.vault = vault
        self.apiKeyManager = apiKeyManager
        self.clipboardManager = clipboardManager
    }

    // MARK: - Public Helpers

    /// Loads all keys in the vault.
    public func loadKeys() async {
        isLoading = true
        errorMessage = nil

        do {
            keys = try await apiKeyManager.fetchKeys(in: vault.id)
        } catch {
            errorMessage = "Failed to load keys: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Deletes an API key.
    ///
    /// - Parameter key: The key to delete.
    public func deleteKey(_ key: APIKey) async throws {
        try await apiKeyManager.deleteKey(key)
        keys.removeAll { $0.id == key.id }
    }

    /// Copies a key's secret to the clipboard.
    ///
    /// - Parameter key: The key whose secret to copy.
    public func copySecret(_ key: APIKey) async throws {
        let secret = try await apiKeyManager.getSecret(for: key)
        await clipboardManager.copy(secret, label: key.label)

        // Mark key as used
        try await apiKeyManager.markAsUsed(key)

        // Update local copy
        if let index = keys.firstIndex(where: { $0.id == key.id }) {
            keys[index].lastUsedAt = Date()
        }
    }
}
