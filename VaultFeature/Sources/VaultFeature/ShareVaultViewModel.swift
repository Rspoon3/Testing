import Foundation
import CloudKit
import TestDriveCore
import TestDrivePersistence

/// View model for sharing a vault with other users.
///
/// Manages CloudKit sharing, participant list, and key wrapping operations.
@MainActor
@Observable
public final class ShareVaultViewModel {

    public var vault: Vault
    public var participants: [VaultParticipant] = []
    public var isLoading = false
    public var errorMessage: String?
    public var share: CKShare?

    private let vaultManager: VaultManager
    private let database: DatabaseManager

    // MARK: - Initializer

    /// Creates a new share vault view model.
    ///
    /// - Parameters:
    ///   - vault: The vault to share.
    ///   - vaultManager: The vault manager.
    ///   - database: The database manager.
    public init(
        vault: Vault,
        vaultManager: VaultManager,
        database: DatabaseManager
    ) {
        self.vault = vault
        self.vaultManager = vaultManager
        self.database = database
    }

    // MARK: - Public Helpers

    /// Loads participants for the vault.
    public func loadParticipants() async {
        isLoading = true
        errorMessage = nil

        do {
            participants = try await vaultManager.fetchParticipants(for: vault.id)

            // Monitor for new participants needing key wrapping
            await monitorForNewParticipants()
        } catch {
            errorMessage = "Failed to load participants: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Presents the CloudKit share sheet.
    ///
    /// This method should be called from a view to present UICloudSharingController.
    ///
    /// - Returns: The CloudKit share record.
    public func shareVault() async throws -> CKShare {
        guard !vault.isShared else {
            // Already shared, return existing share
            if let share {
                return share
            }
            throw SharingError.alreadyShared
        }

        // Create CloudKit share
        let share = try await vaultManager.shareVault(vault)
        self.share = share

        // Update vault as shared
        var updated = vault
        updated.isShared = true
        updated.ckShareID = share.recordID.recordName
        try await vaultManager.updateVault(updated)
        self.vault = updated

        return share
    }

    /// Stops sharing the vault.
    public func stopSharing() async throws {
        guard vault.isShared else { return }

        // Delete all wrapped keys for participants
        for participant in participants where participant.permission != .owner {
            try await vaultManager.revokeShare(for: participant)
        }

        // Update vault as not shared
        var updated = vault
        updated.isShared = false
        updated.ckShareID = nil
        try await vaultManager.updateVault(updated)
        self.vault = updated

        participants.removeAll { $0.permission != .owner }
    }

    /// Updates a participant's permission level.
    ///
    /// - Parameters:
    ///   - participant: The participant to update.
    ///   - permission: The new permission level.
    public func updatePermission(
        for participant: VaultParticipant,
        to permission: SharePermission
    ) async throws {
        var updated = participant
        updated.permission = permission

        try await database.write { _ in
            // Update participant record - SQLiteData API
        }

        // Update local array
        if let index = participants.firstIndex(where: { $0.id == participant.id }) {
            participants[index] = updated
        }
    }

    /// Removes a participant from the vault.
    ///
    /// - Parameter participant: The participant to remove.
    public func removeParticipant(_ participant: VaultParticipant) async throws {
        try await vaultManager.revokeShare(for: participant)
        participants.removeAll { $0.id == participant.id }
    }

    // MARK: - Private Helpers

    /// Monitors for new participants and wraps keys for them.
    private func monitorForNewParticipants() async {
        // Find participants who have accepted but don't have wrapped keys yet
        let needsWrapping = participants.filter { participant in
            participant.acceptanceStatus == .accepted &&
            participant.publicKey != nil &&
            participant.permission != .owner
        }

        for participant in needsWrapping {
            // Check if wrapped key already exists
            let hasWrappedKey = (try? await database.read { _ -> Bool in
                // Query WrappedVaultKey for this participant
                // SQLiteData API would check: vaultID == vault.id && recipientUserID == participant.userID
                return false // Placeholder
            }) ?? false

            if !hasWrappedKey {
                // Wrap key for this participant
                try? await vaultManager.wrapKeyForRecipient(vault: vault, participant: participant)
            }
        }
    }
}

// MARK: - Errors

public enum SharingError: Error {
    case alreadyShared
    case notShared
    case noShare
    case invalidParticipant
}
