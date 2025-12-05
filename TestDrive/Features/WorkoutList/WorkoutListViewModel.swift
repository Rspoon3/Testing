import HealthKit

/// View model for the workout list screen.
@Observable
final class WorkoutListViewModel {
    var workouts: [HKWorkout] = []
    var isLoading = false
    var errorMessage: String?

    private let healthKitService = HealthKitService()
    private let messageStore = WorkoutMessageStore.shared

    // MARK: - Public Helpers

    /// Fetches workouts from HealthKit.
    func fetchWorkouts() async {
        isLoading = true
        errorMessage = nil

        do {
            if !healthKitService.isAuthorized {
                try await healthKitService.requestAuthorization()
            }
            workouts = try await healthKitService.fetchRecentWorkouts()
        } catch {
            errorMessage = "Unable to load workouts. Please check Health permissions."
        }

        isLoading = false
    }

    /// Formats the duration of a workout.
    /// - Parameter workout: The workout to format.
    /// - Returns: A human-readable duration string.
    func formattedDuration(_ workout: HKWorkout) -> String {
        let minutes = Int(workout.duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes) min"
    }

    /// Formats the calories of a workout.
    /// - Parameter workout: The workout to format.
    /// - Returns: A human-readable calories string or nil if not available.
    func formattedCalories(_ workout: HKWorkout) -> String? {
        guard let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
              calories > 0 else {
            return nil
        }
        return "\(Int(calories)) cal"
    }

    /// Formats the date of a workout.
    /// - Parameter workout: The workout to format.
    /// - Returns: A human-readable date string.
    func formattedDate(_ workout: HKWorkout) -> String {
        let formatter = DateFormatter()

        if Calendar.current.isDateInToday(workout.startDate) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if Calendar.current.isDateInYesterday(workout.startDate) {
            formatter.dateFormat = "'Yesterday at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
        }

        return formatter.string(from: workout.startDate)
    }

    /// Checks if a workout has a saved message.
    /// - Parameter workout: The workout to check.
    /// - Returns: Whether a message exists for this workout.
    func hasMessage(for workout: HKWorkout) -> Bool {
        messageStore.message(forWorkoutID: workout.uuid.uuidString) != nil
    }

    /// Gets the saved message for a workout.
    /// - Parameter workout: The workout.
    /// - Returns: The message if one exists.
    func message(for workout: HKWorkout) -> WorkoutMessage? {
        messageStore.message(forWorkoutID: workout.uuid.uuidString)
    }
}
