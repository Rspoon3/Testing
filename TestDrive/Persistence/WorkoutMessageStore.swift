import Foundation
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "WorkoutMessageStore")

/// Persists workout messages to disk.
final class WorkoutMessageStore {
    static let shared = WorkoutMessageStore()

    private let fileManager = FileManager.default
    private let fileName = "workout_messages.json"

    private var fileURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Helpers

    /// Saves a workout message.
    /// - Parameter message: The message to save.
    func save(_ message: WorkoutMessage) {
        var messages = loadAll()
        messages.insert(message, at: 0)
        persist(messages)
        logger.info("💾 Saved message for workout: \(message.workoutID)")
    }

    /// Loads all saved messages, sorted by creation date (newest first).
    /// - Returns: Array of workout messages.
    func loadAll() -> [WorkoutMessage] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let messages = try JSONDecoder().decode([WorkoutMessage].self, from: data)
            return messages.sorted { $0.createdAt > $1.createdAt }
        } catch {
            logger.error("❌ Failed to load messages: \(error.localizedDescription)")
            return []
        }
    }

    /// Finds a message by workout ID.
    /// - Parameter workoutID: The workout UUID string.
    /// - Returns: The message if found.
    func message(forWorkoutID workoutID: String) -> WorkoutMessage? {
        loadAll().first { $0.workoutID == workoutID }
    }

    /// Finds a message by its ID.
    /// - Parameter id: The message ID.
    /// - Returns: The message if found.
    func message(forID id: String) -> WorkoutMessage? {
        loadAll().first { $0.id == id }
    }

    /// Deletes all saved messages.
    func deleteAll() {
        try? fileManager.removeItem(at: fileURL)
        logger.info("🗑️ Deleted all messages")
    }

    /// Returns the count of saved messages.
    var count: Int {
        loadAll().count
    }

    // MARK: - Private Helpers

    private func persist(_ messages: [WorkoutMessage]) {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: fileURL)
        } catch {
            logger.error("❌ Failed to persist messages: \(error.localizedDescription)")
        }
    }
}
