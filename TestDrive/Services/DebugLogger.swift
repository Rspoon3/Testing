import Foundation
import os.log

/// A persistent debug logger that writes timestamped logs to a file.
/// Use this to debug issues when not connected to Xcode.
final class DebugLogger {
    static let shared = DebugLogger()

    private let fileManager = FileManager.default
    private let fileName = "debug_logs.txt"
    private let queue = DispatchQueue(label: "com.rspoon3.TestDrive.debugLogger")
    private let osLogger = Logger(subsystem: "com.rspoon3.TestDrive", category: "DebugLogger")

    private var fileURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    // MARK: - Initializer

    private init() {
        // Create file if it doesn't exist
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }
    }

    // MARK: - Public Helpers

    /// Logs a message with timestamp and category.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: The category/source of the log.
    func log(_ message: String, category: LogCategory) {
        queue.async { [weak self] in
            self?.writeLog(message, category: category)
        }
    }

    /// Reads all logs from the file.
    /// - Returns: The log contents as a string.
    func readLogs() -> String {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return "No logs available."
        }

        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            osLogger.error("Failed to read logs: \(error.localizedDescription)")
            return "Failed to read logs: \(error.localizedDescription)"
        }
    }

    /// Clears all logs.
    func clearLogs() {
        queue.async { [weak self] in
            guard let self else { return }
            try? "".write(to: fileURL, atomically: true, encoding: .utf8)
            osLogger.info("Logs cleared")
        }
    }

    /// Returns the log file size in bytes.
    var logFileSize: Int {
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int else {
            return 0
        }
        return size
    }

    /// Returns the number of log entries.
    var logCount: Int {
        let logs = readLogs()
        return logs.components(separatedBy: "\n").filter { !$0.isEmpty }.count
    }

    // MARK: - Private Helpers

    private func writeLog(_ message: String, category: LogCategory) {
        // Also log to os_log for when Xcode is connected
        osLogger.info("[\(category.rawValue)] \(message)")

        let timestamp = formatTimestamp(Date())
        let logEntry = "[\(timestamp)] [\(category.rawValue)] \(message)\n"

        guard let data = logEntry.data(using: .utf8),
              let fileHandle = try? FileHandle(forWritingTo: fileURL) else {
            return
        }

        defer { try? fileHandle.close() }

        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - Log Category

extension DebugLogger {
    /// Categories for organizing log entries.
    enum LogCategory: String {
        case observer = "OBSERVER"
        case workout = "WORKOUT"
        case weight = "WEIGHT"
        case openAI = "OPENAI"
        case notification = "NOTIFICATION"
        case app = "APP"
        case error = "ERROR"
    }
}
