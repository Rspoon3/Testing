import UIKit
import TestDriveCore
import TestDrivePersistence
import Dependencies
import SQLiteData
import GRDB

/// View model for managing secrets within a credential.
///
/// Handles adding, updating, deleting, and reordering secrets with metadata display.
@MainActor
@Observable
public final class ManageSecretsViewModel {

    // MARK: - Published State

    /// The credential being managed.
    public var credential: Credential

    /// All secrets for this credential.
    /// Automatically updates when database changes.
    @ObservationIgnored
    @FetchAll var secrets: [CredentialSecret]

    /// All history entries for all secrets.
    public var allHistory: [CredentialSecretHistory] = []

    /// Decrypted historical secret values (loaded on demand).
    public var decryptedHistory: [UUID: String] = [:]

    /// Visibility state for historical secrets.
    public var historyVisibility: [UUID: Bool] = [:]

    /// Whether secrets are currently loading.
    public var isLoading = false

    /// Error message to display.
    public var errorMessage: String?

    /// Which secret is being updated (shows update sheet).
    public var secretBeingUpdated: CredentialSecret?

    /// Secret to delete (shows confirmation alert).
    public var secretToDelete: CredentialSecret?

    // MARK: - Dependencies

    private let credentialManager: CredentialManager
    private let haptics: HapticFeedbackManager

    // MARK: - Initializer

    /// Creates a new manage secrets view model.
    ///
    /// - Parameters:
    ///   - credential: The credential to manage secrets for.
    ///   - credentialManager: The credential manager.
    ///   - haptics: The haptic feedback manager.
    public init(
        credential: Credential,
        credentialManager: CredentialManager,
        haptics: HapticFeedbackManager = HapticFeedbackManager()
    ) {
        self.credential = credential
        self.credentialManager = credentialManager
        self.haptics = haptics

        // Initialize @FetchAll with query for this credential's secrets
        _secrets = FetchAll(
            CredentialSecret
                .where { $0.credentialID.eq(credential.id) }
                .order { $0.sortOrder }
        )
    }

    // MARK: - Public Methods

    /// Loads history for all secrets.
    /// Secrets themselves are automatically loaded via @FetchAll.
    public func loadSecrets() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Load all history for all secrets
        var allHistoryEntries: [CredentialSecretHistory] = []
        for secret in secrets {
            let history = try await credentialManager.getSecretHistory(for: secret)
            allHistoryEntries.append(contentsOf: history)
        }
        // Sort by replacedAt descending (newest first)
        allHistory = allHistoryEntries.sorted { $0.replacedAt > $1.replacedAt }
    }

    /// Decrypts a historical secret value.
    ///
    /// - Parameter historyEntry: The history entry to decrypt.
    public func decryptHistoricalSecret(_ historyEntry: CredentialSecretHistory) async throws {
        guard decryptedHistory[historyEntry.id] == nil else { return }

        let decrypted = try await credentialManager.decryptHistoricalSecret(historyEntry, for: credential)
        decryptedHistory[historyEntry.id] = decrypted
    }

    /// Toggles the visibility of a historical secret.
    ///
    /// - Parameter id: The history entry ID.
    public func toggleHistoryVisibility(_ id: UUID) async {
        guard let entry = allHistory.first(where: { $0.id == id }) else { return }

        let isCurrentlyVisible = historyVisibility[id] ?? false
        if !isCurrentlyVisible && decryptedHistory[id] == nil {
            try? await decryptHistoricalSecret(entry)
        }

        historyVisibility[id] = !isCurrentlyVisible
    }

    /// Copies a historical secret to the clipboard and increments its copy count.
    ///
    /// - Parameter historyEntry: The history entry to copy.
    public func copyHistoricalSecret(_ historyEntry: CredentialSecretHistory) async {
        if decryptedHistory[historyEntry.id] == nil {
            try? await decryptHistoricalSecret(historyEntry)
        }

        guard let value = decryptedHistory[historyEntry.id] else { return }

        #if os(iOS)
        UIPasteboard.general.string = value
        #endif

        // Mark history entry as used (increments copy count)
        try? await credentialManager.markHistoricalSecretAsUsed(historyEntry)

        // Reload history to get updated copy count
        try? await loadSecrets()

        haptics.success()
    }

    /// Gets the secret label for a history entry.
    ///
    /// - Parameter historyEntry: The history entry.
    /// - Returns: The label of the secret this history belongs to.
    public func getSecretLabel(for historyEntry: CredentialSecretHistory) -> String {
        secrets.first(where: { $0.id == historyEntry.credentialSecretID })?.secretLabel ?? "Unknown"
    }

    /// Gets the created date of the parent secret for a history entry.
    ///
    /// - Parameter historyEntry: The history entry.
    /// - Returns: The created date of the parent secret.
    public func getParentSecretCreatedDate(for historyEntry: CredentialSecretHistory) -> Date? {
        secrets.first(where: { $0.id == historyEntry.credentialSecretID })?.createdAt
    }

    /// Adds a new secret to the credential.
    ///
    /// - Parameters:
    ///   - label: The secret label.
    ///   - value: The secret value.
    ///   - expiresAt: Optional expiration date.
    ///   - rotateAt: Optional rotation reminder date.
    public func addSecret(
        label: String,
        value: String,
        expiresAt: Date? = nil,
        rotateAt: Date? = nil
    ) async throws {
        errorMessage = nil

        do {
            try await credentialManager.addSecret(
                to: credential,
                label: label,
                value: value,
                expiresAt: expiresAt,
                rotateAt: rotateAt
            )

            // Reload secrets
            try await loadSecrets()
            haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            haptics.error()
            throw error
        }
    }

    /// Updates an existing secret's value.
    ///
    /// - Parameters:
    ///   - secret: The secret to update.
    ///   - newValue: The new secret value.
    ///   - reason: The rotation reason.
    ///   - expiresAt: Optional new expiration date.
    ///   - rotateAt: Optional new rotation reminder date.
    public func updateSecret(
        _ secret: CredentialSecret,
        newValue: String,
        reason: RotationReason = .userInitiated,
        expiresAt: Date? = nil,
        rotateAt: Date? = nil
    ) async throws {
        errorMessage = nil

        do {
            try await credentialManager.updateSecret(
                for: credential,
                label: secret.secretLabel,
                newValue: newValue,
                reason: reason,
                expiresAt: expiresAt,
                rotateAt: rotateAt
            )

            // Reload secrets
            try await loadSecrets()
            haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            haptics.error()
            throw error
        }
    }

    /// Deletes a secret.
    ///
    /// - Parameter secret: The secret to delete.
    public func deleteSecret(_ secret: CredentialSecret) async throws {
        errorMessage = nil

        do {
            try await credentialManager.deleteSecret(
                for: credential,
                label: secret.secretLabel
            )

            // Reload secrets
            try await loadSecrets()
            haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            haptics.error()
            throw error
        }
    }

    /// Reorders secrets.
    ///
    /// - Parameters:
    ///   - source: Source indices.
    ///   - destination: Destination index.
    public func moveSecrets(from source: IndexSet, to destination: Int) {
        // Create mutable copy of secrets to calculate new order
        var mutableSecrets = Array(secrets)
        mutableSecrets.move(fromOffsets: source, toOffset: destination)

        // Update sort order in database (@FetchAll will automatically reload)
        Task {
            do {
                let orderedLabels = mutableSecrets.map(\.secretLabel)
                try await credentialManager.reorderSecrets(
                    for: credential,
                    orderedLabels: orderedLabels
                )
                haptics.success()
            } catch {
                errorMessage = error.localizedDescription
                haptics.error()
            }
        }
    }

    /// Gets the history for a specific secret.
    ///
    /// - Parameter secret: The secret to get history for.
    /// - Returns: Array of history entries.
    public func getHistory(for secret: CredentialSecret) async throws -> [CredentialSecretHistory] {
        try await credentialManager.getSecretHistory(for: secret)
    }

    /// Formats a relative time string for display.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A human-readable relative time string.
    public func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Returns a badge label and color for a secret's status.
    ///
    /// - Parameter secret: The secret to check.
    /// - Returns: Tuple of (label, color) or nil if no badge needed.
    public func statusBadge(for secret: CredentialSecret) -> (label: String, color: String)? {
        if secret.isExpired {
            return ("Expired", "red")
        } else if secret.needsRotation {
            return ("Rotate Soon", "orange")
        } else if secret.status == .active {
            return ("Active", "green")
        } else if secret.status == .revoked {
            return ("Revoked", "gray")
        }
        return nil
    }
}
