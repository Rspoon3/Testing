import Foundation
import TestDriveCore
import TestDrivePersistence

/// View model for the key detail screen.
///
/// Manages secret loading, visibility, and clipboard operations.
@Observable
public final class KeyDetailViewModel {

    public var key: APIKey
    public var secret: String?
    public var isSecretVisible = false
    public var isLoading = false
    public var errorMessage: String?
    public var showingCopyConfirmation = false

    private let apiKeyManager: APIKeyManager
    private let clipboardManager: ClipboardManager
    private let haptics: HapticFeedbackManager

    // MARK: - Initializer

    /// Creates a new key detail view model.
    ///
    /// - Parameters:
    ///   - key: The API key to display.
    ///   - apiKeyManager: The API key manager.
    ///   - clipboardManager: The clipboard manager.
    ///   - haptics: The haptic feedback manager.
    public init(
        key: APIKey,
        apiKeyManager: APIKeyManager,
        clipboardManager: ClipboardManager,
        haptics: HapticFeedbackManager = HapticFeedbackManager()
    ) {
        self.key = key
        self.apiKeyManager = apiKeyManager
        self.clipboardManager = clipboardManager
        self.haptics = haptics
    }

    // MARK: - Public Helpers

    /// Loads the decrypted secret.
    public func loadSecret() async throws {
        guard secret == nil else { return }

        isLoading = true
        errorMessage = nil

        do {
            secret = try await apiKeyManager.getSecret(for: key)
        } catch {
            errorMessage = "Failed to load secret: \(error.localizedDescription)"
            throw error
        }

        isLoading = false
    }

    /// Toggles secret visibility.
    public func toggleSecretVisibility() async {
        if !isSecretVisible && secret == nil {
            try? await loadSecret()
        }
        isSecretVisible.toggle()
        haptics.light()
    }

    /// Copies the secret to clipboard.
    public func copySecret() async {
        guard let secret else {
            try? await loadSecret()
            guard let secret else {
                haptics.error()
                return
            }
        }

        await clipboardManager.copy(secret, label: key.label, keyID: key.id)

        // Mark key as used
        try? await apiKeyManager.markAsUsed(key)
        key.lastUsedAt = Date()

        // Provide haptic feedback
        haptics.success()
        showingCopyConfirmation = true

        // Auto-hide confirmation after 2 seconds
        Task {
            try? await Task.sleep(for: .seconds(2))
            showingCopyConfirmation = false
        }
    }

    /// Deletes the API key.
    public func deleteKey() async throws {
        haptics.warning()
        try await apiKeyManager.deleteKey(key)
        haptics.success()
    }
}
