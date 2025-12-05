import Foundation

/// Heart rate statistics for a workout.
struct WorkoutHeartRate {
    let averageBPM: Int?
    let maxBPM: Int?
    let minBPM: Int?

    /// Formats the heart rate data for the ChatGPT prompt.
    func formatForPrompt() -> String {
        var parts: [String] = []

        if let avg = averageBPM {
            parts.append("average: \(avg) bpm")
        }
        if let max = maxBPM {
            parts.append("max: \(max) bpm")
        }
        if let min = minBPM {
            parts.append("min: \(min) bpm")
        }

        if parts.isEmpty {
            return "Heart rate: Not available"
        }

        return "Heart rate: \(parts.joined(separator: ", "))"
    }
}
