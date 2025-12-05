import Foundation

/// View model for the settings screen.
@Observable
final class SettingsViewModel {
    var selectedAttitudes: Set<Attitude>
    var savedMessagesCount: Int
    var morningSummaryEnabled: Bool
    var eveningSummaryEnabled: Bool
    var morningSummaryHour: Int
    var eveningSummaryHour: Int

    private let userPreferences = UserPreferences.shared
    private let messageStore = WorkoutMessageStore.shared

    // MARK: - Initializer

    init() {
        self.selectedAttitudes = userPreferences.selectedAttitudes
        self.savedMessagesCount = WorkoutMessageStore.shared.count
        self.morningSummaryEnabled = userPreferences.morningSummaryEnabled
        self.eveningSummaryEnabled = userPreferences.eveningSummaryEnabled
        self.morningSummaryHour = userPreferences.morningSummaryHour
        self.eveningSummaryHour = userPreferences.eveningSummaryHour
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

    /// Saves notification settings and reschedules notifications.
    func saveNotificationSettings() {
        userPreferences.morningSummaryEnabled = morningSummaryEnabled
        userPreferences.eveningSummaryEnabled = eveningSummaryEnabled
        userPreferences.morningSummaryHour = morningSummaryHour
        userPreferences.eveningSummaryHour = eveningSummaryHour

        // Reschedule notifications with new settings
        Task {
            await DailySummaryService.shared.scheduleDailySummaries()
        }
    }

    /// Formats an hour as a time string (e.g., "8:00 AM").
    /// - Parameter hour: The hour (0-23).
    /// - Returns: Formatted time string.
    func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    /// Clears all saved messages. Use for testing.
    func clearSavedMessages() {
        messageStore.deleteAll()
        savedMessagesCount = 0
    }
}
