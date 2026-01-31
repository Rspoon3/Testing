import Foundation
import TestDriveCore
import TestDrivePersistence

/// View model for creating or editing a credential with multiple secrets.
///
/// Manages form state, validation, template selection, and save operations.
@MainActor
@Observable
public final class EditCredentialViewModel {

    /// Represents a single secret in the form.
    public struct SecretField: Identifiable, Equatable {
        public let id: UUID
        public var label: String
        public var value: String
        public var isVisible: Bool

        public init(id: UUID = UUID(), label: String = "", value: String = "", isVisible: Bool = false) {
            self.id = id
            self.label = label
            self.value = value
            self.isVisible = isVisible
        }
    }

    // Form fields
    public var label = ""
    public var secrets: [SecretField] = [SecretField()]
    public var websiteDomain = ""
    public var company = ""
    public var environment: APIEnvironment = .production
    public var tags: [String] = []
    public var notes = ""
    public var rotateAt: Date?
    public var enableRotationReminder = false

    // UI state
    public var showingTemplatePicker = false
    public var isSaving = false
    public var errorMessage: String?

    private let vaultID: UUID
    private let credentialManager: CredentialManager
    public let existingCredential: Credential?

    /// Indicates if the form is valid and can be saved.
    public var isValid: Bool {
        let hasLabel = !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if existingCredential != nil {
            // When editing, only require label (secrets managed separately)
            return hasLabel
        } else {
            // When creating, require label and at least one valid secret
            let hasValidSecret = secrets.contains { secret in
                !secret.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !secret.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return hasLabel && hasValidSecret
        }
    }

    // MARK: - Initializer

    /// Creates a new edit credential view model for creating a credential.
    ///
    /// - Parameters:
    ///   - vaultID: The vault to create the credential in.
    ///   - credentialManager: The credential manager.
    public init(
        vaultID: UUID,
        credentialManager: CredentialManager
    ) {
        self.vaultID = vaultID
        self.credentialManager = credentialManager
        self.existingCredential = nil
    }

    /// Creates a new edit credential view model for editing a credential.
    ///
    /// - Parameters:
    ///   - credential: The existing credential to edit.
    ///   - credentialManager: The credential manager.
    public init(
        credential: Credential,
        credentialManager: CredentialManager
    ) {
        self.vaultID = credential.vaultID
        self.credentialManager = credentialManager
        self.existingCredential = credential

        // Pre-fill form with existing values
        self.label = credential.label
        self.websiteDomain = credential.websiteDomain ?? ""
        self.company = credential.company ?? ""
        self.environment = credential.environment
        self.tags = credential.tags
        self.notes = credential.notes
        self.rotateAt = credential.rotateAt
        self.enableRotationReminder = credential.rotateAt != nil

        // Note: Secrets are managed separately for existing credentials
        self.secrets = []
    }

    // MARK: - Public Helpers

    /// Saves the credential (create or update).
    public func save() async throws {
        guard isValid else {
            errorMessage = "Label and at least one secret are required"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            if let existingCredential {
                // Update existing credential (metadata only)
                var updated = existingCredential
                updated.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
                updated.websiteDomain = websiteDomain.isEmpty ? nil : websiteDomain
                updated.company = company.isEmpty ? nil : company
                updated.environment = environment
                updated.tags = tags
                updated.notes = notes
                updated.rotateAt = enableRotationReminder ? rotateAt : nil

                try await credentialManager.updateCredential(updated)
            } else {
                // Create new credential with secrets
                let trimmedSecrets: [(label: String, value: String)] = secrets.compactMap { secret in
                    let trimmedLabel = secret.label.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedValue = secret.value.trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !trimmedLabel.isEmpty && !trimmedValue.isEmpty else {
                        return nil
                    }

                    return (label: trimmedLabel, value: trimmedValue)
                }

                guard !trimmedSecrets.isEmpty else {
                    errorMessage = "At least one secret is required"
                    throw CredentialError.noSecretsProvided
                }

                _ = try await credentialManager.createCredential(
                    label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                    secrets: trimmedSecrets,
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
            isSaving = false
            throw error
        }

        isSaving = false
    }

    /// Applies a template to the secrets list.
    ///
    /// - Parameter template: The template to apply.
    public func applyTemplate(_ template: SecretTemplate) {
        if template.secretLabels.isEmpty {
            // Custom template - just add one empty secret
            secrets = [SecretField()]
        } else {
            // Pre-fill with template labels
            secrets = template.secretLabels.map { label in
                SecretField(label: label, value: "")
            }
        }
    }

    /// Adds a new empty secret field.
    public func addSecret() {
        secrets.append(SecretField())
    }

    /// Removes a secret at the given index.
    ///
    /// - Parameter index: The index to remove.
    public func removeSecret(at index: Int) {
        guard index < secrets.count else { return }
        secrets.remove(at: index)

        // Ensure at least one secret remains
        if secrets.isEmpty {
            secrets.append(SecretField())
        }
    }

    /// Removes secrets at the given offsets.
    ///
    /// - Parameter offsets: The offsets to remove.
    public func removeSecrets(at offsets: IndexSet) {
        secrets.remove(atOffsets: offsets)

        // Ensure at least one secret remains
        if secrets.isEmpty {
            secrets.append(SecretField())
        }
    }

    /// Moves secrets from source indices to destination index.
    ///
    /// - Parameters:
    ///   - source: Source indices.
    ///   - destination: Destination index.
    public func moveSecrets(from source: IndexSet, to destination: Int) {
        secrets.move(fromOffsets: source, toOffset: destination)
    }

    /// Toggles visibility for a specific secret.
    ///
    /// - Parameter id: The secret ID.
    public func toggleSecretVisibility(_ id: UUID) {
        if let index = secrets.firstIndex(where: { $0.id == id }) {
            secrets[index].isVisible.toggle()
        }
    }

    /// Generates a random secret value.
    ///
    /// - Parameter length: The length of the secret (default: 32).
    /// - Returns: A random alphanumeric string.
    public func generateRandomSecret(length: Int = 32) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    /// Generates a random secret for a specific secret field.
    ///
    /// - Parameter id: The secret ID.
    public func generateRandomSecretFor(_ id: UUID) {
        if let index = secrets.firstIndex(where: { $0.id == id }) {
            secrets[index].value = generateRandomSecret()
        }
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
