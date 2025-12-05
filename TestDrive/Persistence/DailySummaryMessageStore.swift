import Foundation
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "DailySummaryMessageStore")

/// Persists daily summary messages to disk.
final class DailySummaryMessageStore {
    static let shared = DailySummaryMessageStore()

    private let fileManager = FileManager.default
    private let fileName = "daily_summary_messages.json"

    private var fileURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Helpers

    /// Saves a daily summary message.
    /// - Parameter message: The message to save.
    func save(_ message: DailySummaryMessage) {
        var messages = loadAll()
        messages.insert(message, at: 0)
        persist(messages)
        logger.info("💾 Saved \(message.summaryType.rawValue) summary")
    }

    /// Loads all saved messages, sorted by creation date (newest first).
    /// - Returns: Array of daily summary messages.
    func loadAll() -> [DailySummaryMessage] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let messages = try JSONDecoder().decode([DailySummaryMessage].self, from: data)
            return messages.sorted { $0.createdAt > $1.createdAt }
        } catch {
            logger.error("❌ Failed to load messages: \(error.localizedDescription)")
            return []
        }
    }

    /// Finds a message by its ID.
    /// - Parameter id: The message ID.
    /// - Returns: The message if found.
    func message(forID id: String) -> DailySummaryMessage? {
        loadAll().first { $0.id == id }
    }

    /// Updates an existing daily summary message by its ID.
    /// - Parameter message: The updated message.
    func update(_ message: DailySummaryMessage) {
        var messages = loadAll()
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            persist(messages)
            logger.info("📝 Updated \(message.summaryType.rawValue) summary: \(message.id)")
        }
    }

    /// Deletes all saved messages.
    func deleteAll() {
        try? fileManager.removeItem(at: fileURL)
        logger.info("🗑️ Deleted all daily summary messages")
    }

    /// Returns the count of saved messages.
    var count: Int {
        loadAll().count
    }

    // MARK: - Private Helpers

    private func persist(_ messages: [DailySummaryMessage]) {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: fileURL)
        } catch {
            logger.error("❌ Failed to persist messages: \(error.localizedDescription)")
        }
    }
}
