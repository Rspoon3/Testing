import Foundation
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "ProcessedWorkoutsStore")

/// Tracks which workouts have already been processed for notifications.
final class ProcessedWorkoutsStore {
    private let defaults = UserDefaults.standard
    private let key = "processedWorkoutIDs"

    // MARK: - Public Helpers

    /// Checks if a workout has been processed.
    /// - Parameter workoutID: The UUID string of the workout.
    /// - Returns: Whether the workout was already processed.
    func isProcessed(_ workoutID: String) -> Bool {
        let ids = loadProcessedIDs()
        let processed = ids.contains(workoutID)
        logger.info("🔍 Checking workout \(workoutID): \(processed ? "already processed" : "new")")
        return processed
    }

    /// Marks a workout as processed.
    /// - Parameter workoutID: The UUID string of the workout.
    func markAsProcessed(_ workoutID: String) {
        var ids = loadProcessedIDs()
        ids.insert(workoutID)

        // Keep only last 100 IDs to prevent unbounded growth
        if ids.count > 100 {
            let sortedIDs = Array(ids).suffix(100)
            ids = Set(sortedIDs)
        }

        defaults.set(Array(ids), forKey: key)
    }

    /// Clears all processed workout IDs.
    func clearAll() {
        defaults.removeObject(forKey: key)
        logger.info("🗑️ Cleared all processed workout IDs")
    }

    /// Returns the count of processed workouts.
    var count: Int {
        loadProcessedIDs().count
    }

    // MARK: - Private Helpers

    private func loadProcessedIDs() -> Set<String> {
        let array = defaults.stringArray(forKey: key) ?? []
        return Set(array)
    }
}
