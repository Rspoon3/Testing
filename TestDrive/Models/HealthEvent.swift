import Foundation

/// A unified type representing either a workout or weight entry in the health list.
enum HealthEvent: Identifiable, Hashable {
    case workout(WorkoutMessage)
    case weight(WeightMessage)

    var id: String {
        switch self {
        case .workout(let message):
            return "workout-\(message.id)"
        case .weight(let message):
            return "weight-\(message.id)"
        }
    }

    /// The date of the health event.
    var date: Date {
        switch self {
        case .workout(let message):
            return message.workoutDate
        case .weight(let message):
            return message.entryDate
        }
    }

    /// The creation date of the message.
    var createdAt: Date {
        switch self {
        case .workout(let message):
            return message.createdAt
        case .weight(let message):
            return message.createdAt
        }
    }
}
