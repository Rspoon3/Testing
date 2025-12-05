import Foundation
import HealthKit

/// Time period for workout statistics.
enum StatsPeriod: String {
    case today = "Today"
    case week = "Last 7 Days"
    case month = "Last 30 Days"
}

/// Statistics for a specific workout type.
struct WorkoutTypeStats {
    let activityType: HKWorkoutActivityType
    let count: Int
    let totalCalories: Double
    let totalDistance: Double
    let totalDuration: TimeInterval
    let maxCalories: Double
    let minCalories: Double
    let maxDistance: Double
    let minDistance: Double
    let maxDuration: TimeInterval
    let minDuration: TimeInterval

    /// Average calories per workout.
    var averageCalories: Double {
        guard count > 0 else { return 0 }
        return totalCalories / Double(count)
    }

    /// Average distance per workout in miles.
    var averageDistance: Double {
        guard count > 0 else { return 0 }
        return totalDistance / Double(count)
    }

    /// Average duration per workout in minutes.
    var averageDuration: Double {
        guard count > 0 else { return 0 }
        return (totalDuration / 60) / Double(count)
    }

    /// Max duration in minutes.
    var maxDurationMinutes: Double {
        maxDuration / 60
    }

    /// Min duration in minutes.
    var minDurationMinutes: Double {
        minDuration / 60
    }

    /// Creates stats from an array of workouts.
    static func from(workouts: [HKWorkout], type: HKWorkoutActivityType) -> WorkoutTypeStats {
        let caloriesValues = workouts.map { $0.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0 }
        let distanceValues = workouts.map { $0.totalDistance?.doubleValue(for: .mile()) ?? 0 }
        let durationValues = workouts.map(\.duration)

        let nonZeroCalories = caloriesValues.filter { $0 > 0 }
        let nonZeroDistance = distanceValues.filter { $0 > 0 }

        return WorkoutTypeStats(
            activityType: type,
            count: workouts.count,
            totalCalories: caloriesValues.reduce(0, +),
            totalDistance: distanceValues.reduce(0, +),
            totalDuration: durationValues.reduce(0, +),
            maxCalories: caloriesValues.max() ?? 0,
            minCalories: nonZeroCalories.min() ?? 0,
            maxDistance: distanceValues.max() ?? 0,
            minDistance: nonZeroDistance.min() ?? 0,
            maxDuration: durationValues.max() ?? 0,
            minDuration: durationValues.min() ?? 0
        )
    }
}

/// Aggregated workout statistics for a time period.
struct PeriodWorkoutStats {
    let period: StatsPeriod
    let totalWorkouts: Int
    let statsByType: [HKWorkoutActivityType: WorkoutTypeStats]

    /// Formats the stats for inclusion in a prompt.
    func formatForPrompt() -> String {
        guard totalWorkouts > 0 else {
            return "\(period.rawValue): No workouts recorded."
        }

        var lines: [String] = []
        lines.append("\(period.rawValue) (\(totalWorkouts) workouts):")

        for (type, stats) in statsByType.sorted(by: { $0.value.count > $1.value.count }) {
            var line = "- \(type.displayName): \(stats.count) workouts"

            if stats.averageCalories > 0 {
                line += ", avg \(Int(stats.averageCalories)) cal"
                if stats.count > 1 {
                    line += " (min: \(Int(stats.minCalories)), max: \(Int(stats.maxCalories)))"
                }
            }

            if stats.averageDistance > 0 {
                line += ", avg \(String(format: "%.1f", stats.averageDistance)) mi"
                if stats.count > 1 {
                    line += " (min: \(String(format: "%.1f", stats.minDistance)), max: \(String(format: "%.1f", stats.maxDistance)))"
                }
            }

            line += ", avg \(Int(stats.averageDuration)) min"
            if stats.count > 1 {
                line += " (min: \(Int(stats.minDurationMinutes)), max: \(Int(stats.maxDurationMinutes)))"
            }

            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    /// Gets stats for a specific workout type.
    func stats(for type: HKWorkoutActivityType) -> WorkoutTypeStats? {
        statsByType[type]
    }

    /// Creates stats from an array of workouts.
    static func from(workouts: [HKWorkout], period: StatsPeriod) -> PeriodWorkoutStats {
        let groupedWorkouts = Dictionary(grouping: workouts, by: \.workoutActivityType)
        var statsByType: [HKWorkoutActivityType: WorkoutTypeStats] = [:]

        for (type, typeWorkouts) in groupedWorkouts {
            statsByType[type] = WorkoutTypeStats.from(workouts: typeWorkouts, type: type)
        }

        return PeriodWorkoutStats(
            period: period,
            totalWorkouts: workouts.count,
            statsByType: statsByType
        )
    }
}

/// All workout statistics including daily, weekly, and monthly.
struct WorkoutStats {
    let today: PeriodWorkoutStats
    let weekly: PeriodWorkoutStats
    let monthly: PeriodWorkoutStats

    /// Formats all stats for inclusion in a prompt.
    func formatForPrompt() -> String {
        [
            today.formatForPrompt(),
            weekly.formatForPrompt(),
            monthly.formatForPrompt()
        ].joined(separator: "\n\n")
    }

    /// Gets monthly stats for a specific workout type (used for comparisons).
    func monthlyStats(for type: HKWorkoutActivityType) -> WorkoutTypeStats? {
        monthly.stats(for: type)
    }
}
