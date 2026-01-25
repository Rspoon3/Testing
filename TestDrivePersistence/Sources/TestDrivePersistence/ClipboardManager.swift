import Foundation
import UIKit

/// A record of clipboard copy activity.
public struct ClipboardCopy: Identifiable, Sendable {
    public let id: UUID
    public let keyID: UUID
    public let keyLabel: String
    public let copiedAt: Date

    public init(id: UUID, keyID: UUID, keyLabel: String, copiedAt: Date) {
        self.id = id
        self.keyID = keyID
        self.keyLabel = keyLabel
        self.copiedAt = copiedAt
    }
}

/// Manages secure clipboard operations with auto-clear functionality.
///
/// This manager provides a secure way to copy sensitive data to the clipboard
/// with automatic clearing after a configurable timeout.
@Observable
public final class ClipboardManager {

    /// Duration in seconds before clipboard is automatically cleared.
    public var autoClearDuration: TimeInterval = 30

    /// Whether to show notifications when copying to clipboard.
    public var notificationsEnabled: Bool = true

    /// Recent clipboard copies for security tracking.
    public var recentCopies: [ClipboardCopy] = []

    private var clearTask: Task<Void, Never>?

    // MARK: - Initializer

    public init() {}

    // MARK: - Public Methods

    /// Copies text to the clipboard with auto-clear.
    ///
    /// - Parameters:
    ///   - text: The text to copy.
    ///   - label: A label describing what was copied (for notifications).
    ///   - keyID: Optional ID of the key being copied (for security tracking).
    public func copy(_ text: String, label: String, keyID: UUID? = nil) async {
        // Copy to clipboard
        await MainActor.run {
            UIPasteboard.general.string = text
        }

        // Track copy activity
        if let keyID = keyID {
            let copy = ClipboardCopy(
                id: UUID(),
                keyID: keyID,
                keyLabel: label,
                copiedAt: Date()
            )
            recentCopies.insert(copy, at: 0)

            // Keep only last 50 copies
            if recentCopies.count > 50 {
                recentCopies = Array(recentCopies.prefix(50))
            }
        }

        // Cancel any existing clear task
        clearTask?.cancel()

        // Capture values to avoid data races
        let duration = autoClearDuration

        // Schedule auto-clear
        clearTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))

            guard !Task.isCancelled else { return }

            await self?.clearClipboard()
        }

        // Show notification if enabled
        if notificationsEnabled {
            await showCopyNotification(label: label, duration: duration)
        }
    }

    /// Manually clears the clipboard.
    public func clearClipboard() async {
        await MainActor.run {
            UIPasteboard.general.string = ""
        }

        clearTask?.cancel()
        clearTask = nil
    }

    /// Cancels the auto-clear timer without clearing the clipboard.
    public func cancelAutoClear() {
        clearTask?.cancel()
        clearTask = nil
    }

    // MARK: - Private Helpers

    /// Shows a notification that text was copied.
    ///
    /// - Parameters:
    ///   - label: Description of what was copied.
    ///   - duration: The duration before auto-clear.
    private func showCopyNotification(label: String, duration: TimeInterval) async {
        // Implementation would show a toast/banner notification
        // For now, this is a placeholder
        await MainActor.run {
            print("Copied \(label) to clipboard. Will auto-clear in \(Int(duration))s")
        }
    }
}
