import Foundation
import TestDriveCore
import TestDrivePersistence
import Dependencies

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
    public var secrets: [CredentialSecret] = []

    /// Whether secrets are currently loading.
    public var isLoading = false

    /// Error message to display.
    public var errorMessage: String?

    /// Which secret is being updated (shows update sheet).
    public var secretBeingUpdated: CredentialSecret?

    /// Which secret's history is being viewed.
    public var secretViewingHistory: CredentialSecret?

    /// Secret to delete (shows confirmation alert).
    public var secretToDelete: CredentialSecret?

    // MARK: - Dependencies

    private let credentialManager: CredentialManager
    @Dependency(\.haptics) private var haptics

    // MARK: - Initializer

    /// Creates a new manage secrets view model.
    ///
    /// - Parameters:
    ///   - credential: The credential to manage secrets for.
    ///   - credentialManager: The credential manager.
    public init(credential: Credential, credentialManager: CredentialManager) {
        self.credential = credential
        self.credentialManager = credentialManager
    }

    // MARK: - Public Methods

    /// Loads all secrets for the credential.
    public func loadSecrets() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        secrets = try await credentialManager.database.read { db in
            try CredentialSecret
                .where { $0.credentialID.eq(credential.id) }
                .order(by: \.sortOrder)
                .fetchAll(db)
        }
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
        secrets.move(fromOffsets: source, toOffset: destination)

        // Update sort order in database
        Task {
            do {
                let orderedLabels = secrets.map(\.secretLabel)
                try await credentialManager.reorderSecrets(
                    for: credential,
                    orderedLabels: orderedLabels
                )
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
