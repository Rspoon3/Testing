//
//  SessionLogWriter.swift
//  TestDrive
//

import Foundation
import os

/// Appends every Bluetooth event to a plain-text log file on disk as it happens.
///
/// The file lives in the app's Documents directory so it survives a crash, appears
/// in Files.app under *On My iPhone → TestDrive*, and can be shared straight out of
/// the app while a session is still running. Writes go through a file handle that is
/// kept open and synchronised on every entry, which is what makes the log a live
/// record rather than something assembled at the end.
///
/// The type is deliberately `nonisolated`: Bluetooth callbacks arrive on the main
/// actor, but file I/O is pushed onto a private serial queue so logging never blocks
/// the UI. All mutable state is confined to that queue.
nonisolated final class SessionLogWriter: @unchecked Sendable {

    /// The URL of the log file being written.
    let fileURL: URL

    private let logger = Logger(subsystem: "com.testdrive.bluetooth", category: "SessionLog")
    private let queue = DispatchQueue(label: "com.testdrive.bluetooth.sessionlog")
    private let startDate: Date

    /// Confined to `queue`.
    private nonisolated(unsafe) var handle: FileHandle?

    /// Confined to `queue`.
    private nonisolated(unsafe) var entryCount = 0

    private static let timestampStyle = Date.ISO8601FormatStyle(timeZone: .current)
        .time(includingFractionalSeconds: true)

    private static let fileNameStyle = Date.ISO8601FormatStyle(dateSeparator: .omitted, timeSeparator: .omitted, timeZone: .current)
        .year()
        .month()
        .day()
        .time(includingFractionalSeconds: false)

    // MARK: - Initializer

    /// Creates a log file for a new capture session and writes its header.
    /// - Parameter deviceName: The name of the peripheral being captured, used in
    ///   the file name and the header.
    init(deviceName: String) {
        let sanitized = deviceName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let safeName = sanitized.isEmpty ? "Unknown" : sanitized

        self.startDate = Date()
        let timestamp = startDate.formatted(Self.fileNameStyle)
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = directory.appendingPathComponent("TestDrive-\(safeName)-\(timestamp).txt")

        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        self.handle = try? FileHandle(forWritingTo: fileURL)

        writeHeader(deviceName: deviceName)
    }

    // MARK: - Public Helpers

    /// Appends a timestamped line to the log.
    /// - Parameters:
    ///   - message: The line to append.
    ///   - category: A short tag identifying the kind of event.
    func log(_ message: String, category: LogCategory = .info) {
        append("[\(Date().formatted(Self.timestampStyle))] [\(category.rawValue)] \(message)\n")
    }

    /// Appends a section heading to the log.
    /// - Parameter title: The heading text.
    func logSection(_ title: String) {
        let rule = String(repeating: "=", count: 72)
        append("\n\(rule)\n\(title)\n\(rule)\n")
    }

    /// Appends a characteristic value together with its raw bytes and decoded fields.
    /// - Parameters:
    ///   - source: A description of where the value came from, e.g. `"Stair Climber Data (2AD0)"`.
    ///   - data: The raw characteristic value.
    ///   - fields: The decoded fields.
    ///   - category: The event kind, typically `.read` or `.notify`.
    func logValue(
        source: String,
        data: Data,
        fields: [DecodedField],
        category: LogCategory
    ) {
        var text = "[\(Date().formatted(Self.timestampStyle))] [\(category.rawValue)] \(source)\n"
        text += "    raw (\(data.count) bytes): \(data.hexDescription)\n"

        for field in fields {
            text += "    \(field.label): \(field.value)"
            if let detail = field.detail {
                text += "  (\(detail))"
            }
            text += "\n"
        }

        append(text)
    }

    /// Appends a closing footer summarising the session, then closes the file.
    func finish() {
        let duration = Date().timeIntervalSince(startDate)
        let rule = String(repeating: "=", count: 72)

        queue.async { [weak self] in
            guard let self, let handle else { return }
            let footer = """

            \(rule)
            Session ended after \(String(format: "%.1f", duration)) s — \(entryCount) entries written.
            \(rule)

            """
            try? handle.write(contentsOf: Data(footer.utf8))
            try? handle.synchronize()
            try? handle.close()
            self.handle = nil
        }
    }

    /// Reads the current contents of the log file.
    ///
    /// Because every entry is synchronised as it is written, this reflects the live
    /// state of the session.
    /// - Returns: The log text, or an empty string if the file cannot be read.
    func currentContents() -> String {
        queue.sync {
            (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
        }
    }

    // MARK: - Private Helpers

    /// Writes the header describing the capture session.
    private func writeHeader(deviceName: String) {
        let rule = String(repeating: "=", count: 72)
        append("""
        TestDrive — Bluetooth GATT capture
        \(rule)
        Device:  \(deviceName)
        Started: \(startDate.formatted(.iso8601))
        File:    \(fileURL.lastPathComponent)

        Every characteristic value is logged with its raw bytes followed by the
        specification-aware decode. If a decode looks wrong, the raw bytes above it
        are the ground truth.
        \(rule)

        """)
    }

    /// Appends text on the private queue and synchronises immediately, so the file on
    /// disk is always current even if the app is killed mid-session.
    private func append(_ text: String) {
        queue.async { [weak self] in
            guard let self, let handle else { return }
            do {
                try handle.write(contentsOf: Data(text.utf8))
                try handle.synchronize()
                entryCount += 1
            } catch {
                logger.error("Failed to append to session log: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - LogCategory

extension SessionLogWriter {
    /// The kinds of events recorded in a capture log.
    enum LogCategory: String, Sendable {
        case info = "INFO"
        case scan = "SCAN"
        case advertisement = "ADV"
        case connection = "CONN"
        case discovery = "DISC"
        case read = "READ"
        case notify = "NOTIFY"
        case write = "WRITE"
        case descriptor = "DESC"
        case error = "ERROR"
    }
}
