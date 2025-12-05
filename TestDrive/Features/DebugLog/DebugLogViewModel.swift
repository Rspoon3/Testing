import Foundation

/// View model for the debug log screen.
@Observable
final class DebugLogViewModel {
    var logs: String = ""
    var logCount: Int = 0
    var logFileSize: String = ""
    var isRefreshing: Bool = false
    var filterText: String = ""

    private let debugLogger = DebugLogger.shared

    // MARK: - Initializer

    init() {
        loadLogs()
    }

    // MARK: - Public Helpers

    /// Loads all logs from the file.
    func loadLogs() {
        logs = debugLogger.readLogs()
        logCount = debugLogger.logCount
        logFileSize = formatFileSize(debugLogger.logFileSize)
    }

    /// Refreshes the logs display.
    func refresh() {
        isRefreshing = true
        loadLogs()
        isRefreshing = false
    }

    /// Clears all logs.
    func clearLogs() {
        debugLogger.clearLogs()
        loadLogs()
    }

    /// Returns filtered logs based on the filter text.
    var filteredLogs: String {
        guard !filterText.isEmpty else {
            return logs
        }

        let lines = logs.components(separatedBy: "\n")
        let filtered = lines.filter { $0.localizedCaseInsensitiveContains(filterText) }
        return filtered.joined(separator: "\n")
    }

    /// Copies logs to clipboard.
    func copyLogs() {
        UIPasteboard.general.string = logs
    }

    /// Shares logs via the share sheet.
    func shareLogs() -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("debug_logs.txt")
        try? logs.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    // MARK: - Private Helpers

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

import UIKit
