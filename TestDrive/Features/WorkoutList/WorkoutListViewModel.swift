import HealthKit
import Foundation

/// View model for the health events list screen.
@Observable
final class WorkoutListViewModel {
    var healthEvents: [HealthEvent] = []
    var isLoading = false
    var errorMessage: String?

    private let healthKitService = HealthKitService()
    private let workoutMessageStore = WorkoutMessageStore.shared
    private let weightMessageStore = WeightMessageStore.shared
    private let dailySummaryMessageStore = DailySummaryMessageStore.shared

    // MARK: - Public Helpers

    /// Fetches workouts, weight entries, and daily summaries.
    func fetchHealthEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            if !healthKitService.isAuthorized {
                try await healthKitService.requestAuthorization()
            }

            // Load all saved messages
            let workoutMessages = workoutMessageStore.loadAll()
            let weightMessages = weightMessageStore.loadAll()
            let dailySummaryMessages = dailySummaryMessageStore.loadAll()

            // Convert to health events
            var events: [HealthEvent] = []
            events.append(contentsOf: workoutMessages.map { .workout($0) })
            events.append(contentsOf: weightMessages.map { .weight($0) })
            events.append(contentsOf: dailySummaryMessages.map { .dailySummary($0) })

            // Sort by date (newest first)
            healthEvents = events.sorted { $0.date > $1.date }
        } catch {
            errorMessage = "Unable to load health data. Please check Health permissions."
        }

        isLoading = false
    }

    /// Formats the duration of a workout message.
    /// - Parameter message: The workout message to format.
    /// - Returns: A human-readable duration string.
    func formattedDuration(_ message: WorkoutMessage) -> String {
        let minutes = Int(message.duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes) min"
    }

    /// Formats the calories of a workout message.
    /// - Parameter message: The workout message to format.
    /// - Returns: A human-readable calories string or nil if not available.
    func formattedCalories(_ message: WorkoutMessage) -> String? {
        guard message.calories > 0 else { return nil }
        return "\(Int(message.calories)) cal"
    }

    /// Formats a date for display.
    /// - Parameter date: The date to format.
    /// - Returns: A human-readable date string.
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()

        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
        }

        return formatter.string(from: date)
    }
}
