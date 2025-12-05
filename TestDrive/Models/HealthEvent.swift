import Foundation

/// A unified type representing a workout, weight entry, or daily summary in the health list.
enum HealthEvent: Identifiable, Hashable {
    case workout(WorkoutMessage)
    case weight(WeightMessage)
    case dailySummary(DailySummaryMessage)

    var id: String {
        switch self {
        case .workout(let message):
            return "workout-\(message.id)"
        case .weight(let message):
            return "weight-\(message.id)"
        case .dailySummary(let message):
            return "summary-\(message.id)"
        }
    }

    /// The date of the health event.
    var date: Date {
        switch self {
        case .workout(let message):
            return message.workoutDate
        case .weight(let message):
            return message.entryDate
        case .dailySummary(let message):
            return message.summaryDate
        }
    }

    /// The creation date of the message.
    var createdAt: Date {
        switch self {
        case .workout(let message):
            return message.createdAt
        case .weight(let message):
            return message.createdAt
        case .dailySummary(let message):
            return message.createdAt
        }
    }
}
