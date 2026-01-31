import Foundation
import Sharing
import SQLiteData
import SwiftUI
import TestDriveCore
import TestDrivePersistence

public enum CredentialOrdering: String, CaseIterable, Sendable {
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
/// Manages credential loading, searching, and deletion within a vault.
@MainActor
@Observable
public final class VaultDetailsViewModel {

    struct KeyRowsRequest: FetchKeyRequest {
        struct Value {
            var pinnedRows: [CredentialRow] = []
            var unpinnedRows: [CredentialRow] = []
        }

        let vaultID: UUID
        let searchText: String
        let ordering: CredentialOrdering

        func fetch(_ db: Database) throws -> Value {
            // Helper to build complete query for pinned or unpinned rows
            func fetchRows(isPinned: Bool) throws -> [CredentialRow] {
                // Step 1: Start from base Credential table and filter by vault
                let baseQuery = Credential.where { apiKey in
                    apiKey.vaultID.eq(vaultID)
                }

                // Step 2: Join with CredentialPreference to get pinned state
                let withPreference = baseQuery
                    .leftJoin(CredentialPreference.all) { $0.id.eq($1.credentialID) }

                // Step 3: Join with FTS5 for search
                let joined = withPreference
                    .join(CredentialText.all) { $0.rowid.eq($2.rowid) }

                // Step 4: Apply filters (pinned state and search)
                let query = joined
                    .where { apiKey, preference, apiKeyText in
                        // Filter by pinned state
                        let pinnedMatch = (preference.isPinned ?? false).eq(isPinned)

                        // Filter by search text if provided
                        if !searchText.isEmpty {
                            pinnedMatch && apiKeyText.match(searchText.quoted())
                        } else {
                            pinnedMatch
                        }
                    }
                    .order { apiKey, _, apiKeyText in
                        switch ordering {
                        case .name:
                            apiKey.label
                        case .dateCreated:
                            apiKey.createdAt.desc()
                        case .lastUsed:
                            apiKey.lastUsedAt.desc(nulls: .last)
                        case .environment:
                            apiKey.environment
                        }
                    }
                    .select { apiKey, preference, _ in
                        CredentialRow.Columns(
                            apiKey: apiKey,
                            isPinned: preference.isPinned ?? false
                        )
                    }

                return try query.fetchAll(db)
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

    @ObservationIgnored @Shared var ordering: CredentialOrdering

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
    public var pinnedKeys: [Credential] {
        keyRows.pinnedRows.map(\.credential)
    }

    /// Unpinned keys (search-filtered at database level).
    public var unpinnedKeys: [Credential] {
        keyRows.unpinnedRows.map(\.credential)
    }

    private let initialVault: Vault
    public let vaultID: UUID
    public let credentialManager: CredentialManager
    public let clipboardManager: ClipboardManager
    public let vaultManager: VaultManager

    // MARK: - Initializer

    /// Creates a new vault details view model.
    ///
    /// - Parameters:
    ///   - vault: The vault to display keys from.
    ///   - credentialManager: The credential manager.
    ///   - clipboardManager: The clipboard manager.
    ///   - vaultManager: The vault manager.
    public init(
        vault: Vault,
        credentialManager: CredentialManager,
        clipboardManager: ClipboardManager,
        vaultManager: VaultManager
    ) {
        self.initialVault = vault
        self.vaultID = vault.id
        self.credentialManager = credentialManager
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
            animation: .smooth(duration: 0.35)
        )
    }

    // MARK: - Public Helpers

    /// Updates the sorting order for keys.
    public func orderingButtonTapped(_ ordering: CredentialOrdering) async {
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
            // Debounce: wait 300ms before executing search
            try? await Task.sleep(for: .seconds(0.3))

            // If task was cancelled during sleep, exit early
            guard !Task.isCancelled else { return }

            await withErrorReporting {
                try await $keyRows.load(
                    KeyRowsRequest(vaultID: vaultID, searchText: searchText, ordering: ordering),
                    animation: .default
                )
            }
        }
    }

    /// Deletes an credential.
    ///
    /// - Parameter key: The key to delete.
    public func deleteKey(_ key: Credential) async throws {
        try await credentialManager.deleteKey(key)
        // @FetchAll automatically updates keys array
    }

    /// Copies a key's secret to the clipboard.
    ///
    /// - Parameter key: The key whose secret to copy.
    public func copySecret(_ key: Credential) async throws {
        let secret = try await credentialManager.getSecret(for: key)
        clipboardManager.copy(secret, label: key.label, keyID: key.id)

        // Mark key as used
        try await credentialManager.markAsUsed(key)
        // @FetchAll automatically updates keys array
    }

    /// Toggles the pinned state of an credential.
    ///
    /// - Parameter key: The key to toggle.
    public func togglePin(for key: Credential) async {
        await withErrorReporting {
            try await credentialManager.toggleKeyPin(key)
        }
    }

    /// Shows the vault configuration screen.
    public func showVaultConfiguration() {
        vaultForm = Vault.Draft(vault)
    }
}

// MARK: - String Extensions

private extension String {
    /// Wraps each word in quotes for FTS5 phrase matching with prefix support.
    ///
    /// This ensures multi-word searches use AND logic (all words must match)
    /// rather than OR logic (any word matches). The last word gets a wildcard
    /// suffix for prefix matching.
    ///
    /// Examples:
    /// - "gi" becomes "gi*" (matches "GitHub")
    /// - "stripe prod" becomes "\"stripe\" prod*" (matches "Stripe Production")
    func quoted() -> String {
        let words = split(separator: " ").map(String.init)
        guard !words.isEmpty else { return self }

        // Add wildcard to last word for prefix matching
        if words.count == 1 {
            return "\(words[0])*"
        } else {
            let quotedWords = words.dropLast().map { "\"\($0)\"" }
            let lastWord = "\(words.last!)*"
            return (quotedWords + [lastWord]).joined(separator: " ")
        }
    }
}
