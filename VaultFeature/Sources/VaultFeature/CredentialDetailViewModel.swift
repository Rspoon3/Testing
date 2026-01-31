import Foundation
import TestDriveCore
import TestDrivePersistence
import Dependencies
import SQLiteData
import GRDB

/// View model for displaying credential details.
///
/// Manages state for viewing and copying a credential's multiple secrets.
@MainActor
@Observable
public final class CredentialDetailViewModel {

    // MARK: - Published State

    /// The credential being displayed.
    public var key: Credential

    /// All secrets for this credential (metadata only, not decrypted).
    public var secrets: [CredentialSecret] = []

    /// Decrypted secret values (loaded on demand for performance).
    public var decryptedSecrets: [UUID: String] = [:]

    /// Per-secret visibility state.
    public var secretVisibility: [UUID: Bool] = [:]

    /// Whether to show the copy confirmation indicator and which secret.
    public var showingCopyConfirmation: UUID?

    /// Whether secrets are currently loading.
    public var isLoading = false

    // MARK: - Dependencies

    public let credentialManager: CredentialManager
    @Dependency(\.pasteboard) private var pasteboard
    @Dependency(\.haptics) private var haptics

    // MARK: - Initializer

    /// Creates a new credential detail view model.
    ///
    /// - Parameters:
    ///   - key: The credential to display.
    ///   - credentialManager: The credential manager for loading secrets.
    public init(key: Credential, credentialManager: CredentialManager) {
        self.key = key
        self.credentialManager = credentialManager
    }

    // MARK: - Public Methods

    /// Loads all secrets for the credential (metadata only).
    public func loadSecrets() async throws {
        guard secrets.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        secrets = try await credentialManager.database.read { db in
            try CredentialSecret
                .where { $0.credentialID.eq(key.id) }
                .order(by: \.sortOrder)
                .fetchAll(db)
        }
    }

    /// Decrypts and caches a specific secret value (lazy loading).
    ///
    /// - Parameter secret: The secret to decrypt.
    public func decryptSecret(_ secret: CredentialSecret) async throws {
        guard decryptedSecrets[secret.id] == nil else { return }

        let decrypted = try await credentialManager.decryptSecret(secret)
        decryptedSecrets[secret.id] = decrypted
    }

    /// Toggles the visibility of a specific secret.
    ///
    /// - Parameter id: The secret ID.
    public func toggleSecretVisibility(_ id: UUID) async {
        // Find the secret
        guard let secret = secrets.first(where: { $0.id == id }) else { return }

        // If making visible and not yet decrypted, decrypt it first
        let isCurrentlyVisible = secretVisibility[id] ?? false
        if !isCurrentlyVisible && decryptedSecrets[id] == nil {
            try? await decryptSecret(secret)
        }

        // Toggle visibility
        secretVisibility[id] = !isCurrentlyVisible
    }

    /// Copies a specific secret to the clipboard and marks it as used.
    ///
    /// - Parameter secret: The secret to copy.
    public func copySecret(_ secret: CredentialSecret) async {
        // Decrypt if needed
        if decryptedSecrets[secret.id] == nil {
            try? await decryptSecret(secret)
        }

        guard let value = decryptedSecrets[secret.id] else { return }

        // Copy to clipboard
        pasteboard.copy(value)

        // Mark secret as used
        try? await credentialManager.markSecretAsUsed(secret)

        // Provide haptic feedback
        haptics.success()
        showingCopyConfirmation = secret.id

        // Auto-hide confirmation after 2 seconds
        try? await Task.sleep(for: .seconds(2))
        if showingCopyConfirmation == secret.id {
            showingCopyConfirmation = nil
        }
    }

    /// Deletes the credential and all its secrets.
    public func deleteKey() async throws {
        haptics.warning()
        try await credentialManager.deleteCredential(key)
        haptics.success()
    }
}
