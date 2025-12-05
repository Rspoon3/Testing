import Foundation

/// A persisted message generated for a workout.
struct WorkoutMessage: Codable, Identifiable, Hashable {
    let id: String
    let workoutID: String
    let activityType: String
    let activityName: String
    let duration: TimeInterval
    let calories: Double
    let distance: Double
    let message: String
    let attitudes: String
    let workoutDate: Date
    let createdAt: Date

    // MARK: - Initializer

    init(
        id: String = UUID().uuidString,
        workoutID: String,
        activityType: String,
        activityName: String,
        duration: TimeInterval,
        calories: Double,
        distance: Double,
        message: String,
        attitudes: String,
        workoutDate: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.workoutID = workoutID
        self.activityType = activityType
        self.activityName = activityName
        self.duration = duration
        self.calories = calories
        self.distance = distance
        self.message = message
        self.attitudes = attitudes
        self.workoutDate = workoutDate
        self.createdAt = createdAt
    }

    // MARK: - Public Helpers

    /// Formatted duration string.
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }

    /// Formatted calories string.
    var formattedCalories: String? {
        guard calories > 0 else { return nil }
        return "\(Int(calories)) cal"
    }

    /// Formatted distance string.
    var formattedDistance: String? {
        guard distance > 0 else { return nil }
        return String(format: "%.1f mi", distance)
    }
}
