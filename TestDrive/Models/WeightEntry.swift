import Foundation
import HealthKit

/// A weight entry from HealthKit.
struct WeightEntry: Identifiable {
    let id: String
    let weightInPounds: Double
    let date: Date

    /// Formatted weight string.
    var formattedWeight: String {
        String(format: "%.1f lbs", weightInPounds)
    }
}

/// Statistics about weight entries over a period.
struct WeightStats {
    let entries: [WeightEntry]
    let currentWeight: Double?
    let previousWeight: Double?
    let monthAgoWeight: Double?
    let minWeight: Double?
    let maxWeight: Double?
    let averageWeight: Double?

    /// Change from previous weight entry.
    var changeFromPrevious: Double? {
        guard let current = currentWeight, let previous = previousWeight else { return nil }
        return current - previous
    }

    /// Change from a month ago.
    var changeFromMonthAgo: Double? {
        guard let current = currentWeight, let monthAgo = monthAgoWeight else { return nil }
        return current - monthAgo
    }

    /// Formats the weight stats for the ChatGPT prompt.
    func formatForPrompt() -> String {
        var lines: [String] = []

        if let current = currentWeight {
            lines.append("Current weight: \(String(format: "%.1f", current)) lbs")
        }

        if let change = changeFromPrevious {
            let direction = change > 0 ? "up" : "down"
            lines.append("Change from last weigh-in: \(direction) \(String(format: "%.1f", abs(change))) lbs")
        }

        if let change = changeFromMonthAgo {
            let direction = change > 0 ? "up" : "down"
            lines.append("Change from 30 days ago: \(direction) \(String(format: "%.1f", abs(change))) lbs")
        }

        if let min = minWeight, let max = maxWeight {
            lines.append("30-day range: \(String(format: "%.1f", min)) - \(String(format: "%.1f", max)) lbs")
        }

        if let avg = averageWeight {
            lines.append("30-day average: \(String(format: "%.1f", avg)) lbs")
        }

        lines.append("Total weigh-ins this month: \(entries.count)")

        return lines.joined(separator: "\n")
    }
}
