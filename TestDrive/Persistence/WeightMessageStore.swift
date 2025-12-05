import Foundation
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "WeightMessageStore")

/// Persists weight messages to disk.
final class WeightMessageStore {
    static let shared = WeightMessageStore()

    private let fileManager = FileManager.default
    private let fileName = "weight_messages.json"

    private var fileURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Helpers

    /// Saves a weight message.
    /// - Parameter message: The message to save.
    func save(_ message: WeightMessage) {
        var messages = loadAll()
        messages.insert(message, at: 0)
        persist(messages)
        logger.info("💾 Saved message for weight entry: \(message.weightEntryID)")
    }

    /// Loads all saved messages, sorted by creation date (newest first).
    /// - Returns: Array of weight messages.
    func loadAll() -> [WeightMessage] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let messages = try JSONDecoder().decode([WeightMessage].self, from: data)
            return messages.sorted { $0.createdAt > $1.createdAt }
        } catch {
            logger.error("❌ Failed to load messages: \(error.localizedDescription)")
            return []
        }
    }

    /// Finds a message by weight entry ID.
    /// - Parameter weightEntryID: The weight entry UUID string.
    /// - Returns: The message if found.
    func message(forWeightEntryID weightEntryID: String) -> WeightMessage? {
        loadAll().first { $0.weightEntryID == weightEntryID }
    }

    /// Finds a message by its ID.
    /// - Parameter id: The message ID.
    /// - Returns: The message if found.
    func message(forID id: String) -> WeightMessage? {
        loadAll().first { $0.id == id }
    }

    /// Deletes all saved messages.
    func deleteAll() {
        try? fileManager.removeItem(at: fileURL)
        logger.info("🗑️ Deleted all weight messages")
    }

    /// Returns the count of saved messages.
    var count: Int {
        loadAll().count
    }

    // MARK: - Private Helpers

    private func persist(_ messages: [WeightMessage]) {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: fileURL)
        } catch {
            logger.error("❌ Failed to persist messages: \(error.localizedDescription)")
        }
    }
}
