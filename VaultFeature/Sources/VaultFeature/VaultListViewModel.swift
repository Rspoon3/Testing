import Foundation
import Sharing
import SQLiteData
import SwiftUI
import TestDriveCore
import TestDrivePersistence

public enum VaultOrdering: String, CaseIterable, Sendable {
    case name = "Name"
    case dateCreated = "Date Created"
    case keyCount = "Key Count"
    case lastUpdated = "Last Updated"

    var icon: Image {
        switch self {
        case .name: Image(systemName: "textformat")
        case .dateCreated: Image(systemName: "calendar")
        case .keyCount: Image(systemName: "number")
        case .lastUpdated: Image(systemName: "clock")
        }
    }
}

/// View model for the vault list screen.
///
/// Manages vault fetching, creation, and deletion operations.
@MainActor
@Observable
public final class VaultListViewModel {

    struct VaultRowsRequest: FetchKeyRequest {
        struct Value {
            var pinnedRows: [VaultRow] = []
            var unpinnedRows: [VaultRow] = []
        }

        let searchText: String
        let ordering: VaultOrdering

        func fetch(_ db: Database) throws -> Value {
            // Build base query with search filter
            var baseQuery = VaultRow.all

            if !searchText.isEmpty {
                baseQuery = baseQuery.where { $0.vault.name.contains(searchText) }
            }

            // Helper to apply ordering and fetch
            func fetchWithOrdering(_ query: Where<VaultRow>) throws -> [VaultRow] {
                try query
                    .order {
                        switch ordering {
                        case .name:
                            $0.vault.name
                        case .dateCreated:
                            $0.vault.createdAt.desc()
                        case .keyCount:
                            $0.keyCount.desc()
                        case .lastUpdated:
                            $0.vault.updatedAt.desc()
                        }
                    }
                    .fetchAll(db)
            }

            // Execute both queries in single transaction
            return try Value(
                pinnedRows: fetchWithOrdering(baseQuery.where(\.isPinned)),
                unpinnedRows: fetchWithOrdering(baseQuery.where { !$0.isPinned })
            )
        }
    }

    @ObservationIgnored
    @Fetch var vaultRows = VaultRowsRequest.Value()

    @ObservationIgnored @Shared var ordering: VaultOrdering

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
    private let credentialManager: CredentialManager

    // MARK: - Initializer

    /// Creates a new vault list view model.
    ///
    /// - Parameters:
    ///   - vaultManager: The vault manager for vault operations.
    ///   - credentialManager: The credential manager for key operations.
    public init(
        vaultManager: VaultManager,
        credentialManager: CredentialManager
    ) {
        self.vaultManager = vaultManager
        self.credentialManager = credentialManager

        // Initialize sorting preference from AppStorage
        _ordering = Shared(
            wrappedValue: .name,
            .appStorage("vaultOrdering")
        )

        // Initialize @Fetch with initial request (data loads synchronously)
        let currentOrdering = _ordering.wrappedValue
        _vaultRows = Fetch(
            wrappedValue: VaultRowsRequest.Value(),
            VaultRowsRequest(searchText: "", ordering: currentOrdering),
            animation: .default
        )
    }

    // MARK: - Public Helpers

    /// Loads vaults from the database.
    public func loadVaults() async {
        // Data already loaded in init - no action needed
        // This is kept for compatibility with view's .task modifier
    }

    /// Updates the sorting order for vaults.
    public func orderingButtonTapped(_ ordering: VaultOrdering) async {
        $ordering.withLock { $0 = ordering }
        updateQuery()
    }

    /// Updates the vault query based on current search text.
    public func updateQuery() {
        let searchText = self.searchText
        let ordering = self.ordering

        searchTask?.cancel()
        searchTask = Task {
            await withErrorReporting {
                try await $vaultRows.load(
                    VaultRowsRequest(searchText: searchText, ordering: ordering),
                    animation: .default
                )
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

    /// Returns the credential manager for navigation.
    public func getCredentialManager() -> CredentialManager {
        credentialManager
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
