import Foundation

/// View model for the settings screen.
@Observable
final class SettingsViewModel {
    var selectedAttitudes: Set<Attitude>
    var savedMessagesCount: Int

    private let userPreferences = UserPreferences.shared
    private let messageStore = WorkoutMessageStore.shared

    // MARK: - Initializer

    init() {
        self.selectedAttitudes = userPreferences.selectedAttitudes
        self.savedMessagesCount = WorkoutMessageStore.shared.count
    }

    // MARK: - Public Helpers

    /// Saves the selected attitudes to user preferences.
    func saveAttitudes() {
        userPreferences.selectedAttitudes = selectedAttitudes
    }

    /// Toggles an attitude selection and saves.
    /// - Parameter attitude: The attitude to toggle.
    func toggleAttitude(_ attitude: Attitude) {
        if selectedAttitudes.contains(attitude) {
            // Don't allow deselecting the last one
            if selectedAttitudes.count > 1 {
                selectedAttitudes.remove(attitude)
            }
        } else {
            selectedAttitudes.insert(attitude)
        }
        saveAttitudes()
    }

    /// Checks if an attitude is selected.
    /// - Parameter attitude: The attitude to check.
    /// - Returns: Whether the attitude is selected.
    func isSelected(_ attitude: Attitude) -> Bool {
        selectedAttitudes.contains(attitude)
    }

    /// Clears all saved messages. Use for testing.
    func clearSavedMessages() {
        messageStore.deleteAll()
        savedMessagesCount = 0
    }
}
