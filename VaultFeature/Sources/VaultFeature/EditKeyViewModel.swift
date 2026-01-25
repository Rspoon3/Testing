import Foundation
import TestDriveCore
import TestDrivePersistence

/// View model for creating or editing an API key.
///
/// Manages form state, validation, and save operations.
@MainActor
@Observable
public final class EditKeyViewModel {

    // Form fields
    public var label = ""
    public var secret = ""
    public var websiteDomain = ""
    public var company = ""
    public var environment: APIEnvironment = .production
    public var tags: [String] = []
    public var notes = ""
    public var rotateAt: Date?
    public var enableRotationReminder = false

    // UI state
    public var isSecretVisible = false
    public var isSaving = false
    public var errorMessage: String?

    private let vaultID: UUID
    private let apiKeyManager: APIKeyManager
    public let existingKey: APIKey?

    /// Indicates if the form is valid and can be saved.
    public var isValid: Bool {
        let hasLabel = !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if existingKey != nil {
            // When editing, only require label (can't edit secret)
            return hasLabel
        } else {
            // When creating, require both label and secret
            let hasSecret = !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasLabel && hasSecret
        }
    }

    // MARK: - Initializer

    /// Creates a new edit key view model for creating a key.
    ///
    /// - Parameters:
    ///   - vaultID: The vault to create the key in.
    ///   - apiKeyManager: The API key manager.
    public init(
        vaultID: UUID,
        apiKeyManager: APIKeyManager
    ) {
        self.vaultID = vaultID
        self.apiKeyManager = apiKeyManager
        self.existingKey = nil
    }

    /// Creates a new edit key view model for editing a key.
    ///
    /// - Parameters:
    ///   - key: The existing key to edit.
    ///   - apiKeyManager: The API key manager.
    public init(
        key: APIKey,
        apiKeyManager: APIKeyManager
    ) {
        self.vaultID = key.vaultID
        self.apiKeyManager = apiKeyManager
        self.existingKey = key

        // Pre-fill form with existing values
        self.label = key.label
        self.websiteDomain = key.websiteDomain ?? ""
        self.company = key.company ?? ""
        self.environment = key.environment
        self.tags = key.tags
        self.notes = key.notes
        self.rotateAt = key.rotateAt
        self.enableRotationReminder = key.rotateAt != nil

        // Note: Cannot edit existing secret, only create new
        self.secret = ""
    }

    // MARK: - Public Helpers

    /// Saves the API key (create or update).
    public func save() async throws {
        guard isValid else {
            errorMessage = "Label and secret are required"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            if let existingKey {
                // Update existing key (metadata only)
                var updated = existingKey
                updated.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
                updated.websiteDomain = websiteDomain.isEmpty ? nil : websiteDomain
                updated.company = company.isEmpty ? nil : company
                updated.environment = environment
                updated.tags = tags
                updated.notes = notes
                updated.rotateAt = enableRotationReminder ? rotateAt : nil

                try await apiKeyManager.updateKey(updated)
            } else {
                // Create new key
                _ = try await apiKeyManager.createKey(
                    label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                    secret: secret.trimmingCharacters(in: .whitespacesAndNewlines),
                    vaultID: vaultID,
                    websiteDomain: websiteDomain.isEmpty ? nil : websiteDomain,
                    company: company.isEmpty ? nil : company,
                    environment: environment,
                    tags: tags,
                    notes: notes,
                    rotateAt: enableRotationReminder ? rotateAt : nil
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isSaving = false
    }

    /// Generates a random API key secret.
    ///
    /// - Parameter length: The length of the secret (default: 32).
    /// - Returns: A random alphanumeric string.
    public func generateRandomSecret(length: Int = 32) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    /// Adds a new tag.
    ///
    /// - Parameter tag: The tag to add.
    public func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
    }

    /// Removes a tag.
    ///
    /// - Parameter tag: The tag to remove.
    public func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}
