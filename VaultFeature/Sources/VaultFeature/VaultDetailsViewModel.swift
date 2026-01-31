import Foundation
import Sharing
import SQLiteData
import SwiftUI
import TestDriveCore
import TestDrivePersistence

public enum KeyOrdering: String, CaseIterable, Sendable {
    case name = "Name"
    case dateCreated = "Date Created"
    case lastUsed = "Last Used"
    case environment = "Environment"

    var icon: Image {
        switch self {
        case .name: Image(systemName: "textformat")
        case .dateCreated: Image(systemName: "calendar")
        case .lastUsed: Image(systemName: "clock")
        case .environment: Image(systemName: "server.rack")
        }
    }
}

/// View model for the vault details screen.
///
/// Manages API key loading, searching, and deletion within a vault.
@MainActor
@Observable
public final class VaultDetailsViewModel {

    struct KeyRowsRequest: FetchKeyRequest {
        struct Value {
            var pinnedRows: [APIKeyRow] = []
            var unpinnedRows: [APIKeyRow] = []
        }

        let vaultID: UUID
        let searchText: String
        let ordering: KeyOrdering

        func fetch(_ db: Database) throws -> Value {
            // Helper to build complete query for pinned or unpinned rows
            func fetchRows(isPinned: Bool) throws -> [APIKeyRow] {
                try APIKeyRow
                    .where { $0.apiKey.vaultID.eq(vaultID) }
                    .where { isPinned ? $0.isPinned : !$0.isPinned }
                    .join(APIKeyText.all) { $0.apiKey.rowid.eq($1.rowid) }
                    .where { _, apiKeyText in
                        if !searchText.isEmpty {
                            apiKeyText.match(searchText)
                        }
                    }
                    .select { row, _ in row }
                    .order {
                        switch ordering {
                        case .name:
                            $0.apiKey.label
                        case .dateCreated:
                            $0.apiKey.createdAt.desc()
                        case .lastUsed:
                            $0.apiKey.lastUsedAt.desc(nulls: .last)
                        case .environment:
                            $0.apiKey.environment
                        }
                    }
                    .fetchAll(db)
            }

            // Execute both queries in single transaction
            return try Value(
                pinnedRows: fetchRows(isPinned: true),
                unpinnedRows: fetchRows(isPinned: false)
            )
        }
    }

    @ObservationIgnored
    @Fetch var keyRows = KeyRowsRequest.Value()

    @ObservationIgnored @FetchOne(Vault.none)
    private var observedVault: Vault?

    @ObservationIgnored @Shared var ordering: KeyOrdering

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

    /// Pinned keys (search-filtered at database level).
    public var pinnedKeys: [APIKey] {
        keyRows.pinnedRows.map(\.apiKey)
    }

    /// Unpinned keys (search-filtered at database level).
    public var unpinnedKeys: [APIKey] {
        keyRows.unpinnedRows.map(\.apiKey)
    }

    private let initialVault: Vault
    public let vaultID: UUID
    public let apiKeyManager: APIKeyManager
    public let clipboardManager: ClipboardManager
    public let vaultManager: VaultManager

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

        // Initialize sorting preference from AppStorage
        _ordering = Shared(
            wrappedValue: .name,
            .appStorage("keyOrdering")
        )

        // Set up vault observation
        _observedVault = FetchOne(Vault.where { $0.id.eq(vault.id) })

        // Initialize @Fetch with initial request (data loads synchronously)
        let currentOrdering = _ordering.wrappedValue
        _keyRows = Fetch(
            wrappedValue: KeyRowsRequest.Value(),
            KeyRowsRequest(vaultID: vault.id, searchText: "", ordering: currentOrdering),
            animation: .default
        )
    }

    // MARK: - Public Helpers

    /// Updates the sorting order for keys.
    public func orderingButtonTapped(_ ordering: KeyOrdering) async {
        $ordering.withLock { $0 = ordering }
        updateQuery()
    }

    /// Main task called when view appears or refreshed.
    public func task() async {
        // Data already loaded in init - only reload on explicit refresh
        isLoading = true
        errorMessage = nil
        updateQuery()
        isLoading = false
    }

    /// Updates the key query based on search text and ordering.
    private func updateQuery() {
        let searchText = self.searchText
        let ordering = self.ordering

        searchTask?.cancel()
        searchTask = Task {
            await withErrorReporting {
                try await $keyRows.load(
                    KeyRowsRequest(vaultID: vaultID, searchText: searchText, ordering: ordering),
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
