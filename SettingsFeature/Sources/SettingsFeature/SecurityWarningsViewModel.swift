import Foundation
import TestDriveCore
import TestDrivePersistence

/// View model for the security warnings screen.
///
/// Manages detection and tracking of security concerns including expired keys,
/// rotation reminders, and recent clipboard activity.
@Observable
public final class SecurityWarningsViewModel {

    public var warnings: [SecurityWarning] = []
    public var isLoading = false
    public var errorMessage: String?

    private let apiKeyManager: APIKeyManager
    private let clipboardManager: ClipboardManager
    private let database: DatabaseManager

    // MARK: - Initializer

    /// Creates a new security warnings view model.
    ///
    /// - Parameters:
    ///   - apiKeyManager: The API key manager for key operations.
    ///   - clipboardManager: The clipboard manager for activity tracking.
    ///   - database: The database manager for queries.
    public init(
        apiKeyManager: APIKeyManager,
        clipboardManager: ClipboardManager,
        database: DatabaseManager
    ) {
        self.apiKeyManager = apiKeyManager
        self.clipboardManager = clipboardManager
        self.database = database
    }

    // MARK: - Public Helpers

    /// Loads all security warnings.
    public func loadWarnings() async {
        isLoading = true
        errorMessage = nil
        warnings = []

        do {
            // Load expired keys
            let expiredKeys = try await findExpiredKeys()
            warnings.append(contentsOf: expiredKeys)

            // Load keys needing rotation
            let rotationKeys = try await findKeysNeedingRotation()
            warnings.append(contentsOf: rotationKeys)

            // Load recent clipboard activity
            let clipboardWarnings = await findRecentClipboardActivity()
            warnings.append(contentsOf: clipboardWarnings)

            // Sort by severity (high → medium → low) then by date
            warnings.sort { lhs, rhs in
                if lhs.severity != rhs.severity {
                    return lhs.severity.rawValue > rhs.severity.rawValue
                }
                return lhs.date > rhs.date
            }

        } catch {
            errorMessage = "Failed to load warnings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Dismisses a warning.
    ///
    /// - Parameter warning: The warning to dismiss.
    public func dismissWarning(_ warning: SecurityWarning) {
        warnings.removeAll { $0.id == warning.id }
    }

    // MARK: - Private Helpers

    /// Finds keys that have expired.
    private func findExpiredKeys() async throws -> [SecurityWarning] {
        let now = Date()

        // Query database for keys with rotateAt date in the past
        let allKeys = try await database.read { _ in
            // db.query(APIKey.self).filter(\.rotateAt != nil).all()
            // Placeholder: In real implementation, query all keys
            return [APIKey]() // Placeholder
        }

        let expired = allKeys.filter { key in
            guard let rotateAt = key.rotateAt else { return false }
            return rotateAt < now
        }

        return expired.map { key in
            let daysExpired = Calendar.current.dateComponents([.day], from: key.rotateAt!, to: now).day ?? 0
            return SecurityWarning(
                id: UUID(),
                type: .expired,
                keyID: key.id,
                keyLabel: key.label,
                message: "'\(key.label)' expired \(daysExpired) days ago",
                severity: .high,
                date: key.rotateAt!
            )
        }
    }

    /// Finds keys approaching rotation date.
    private func findKeysNeedingRotation() async throws -> [SecurityWarning] {
        let now = Date()
        let warningThreshold = Calendar.current.date(byAdding: .day, value: 7, to: now)!

        // Query database for keys with rotateAt date within 7 days
        let allKeys = try await database.read { _ in
            // db.query(APIKey.self).filter(\.rotateAt != nil).all()
            return [APIKey]() // Placeholder
        }

        let needsRotation = allKeys.filter { key in
            guard let rotateAt = key.rotateAt else { return false }
            return rotateAt > now && rotateAt <= warningThreshold
        }

        return needsRotation.map { key in
            let daysUntil = Calendar.current.dateComponents([.day], from: now, to: key.rotateAt!).day ?? 0
            return SecurityWarning(
                id: UUID(),
                type: .needsRotation,
                keyID: key.id,
                keyLabel: key.label,
                message: "'\(key.label)' should be rotated in \(daysUntil) days",
                severity: .medium,
                date: key.rotateAt!
            )
        }
    }

    /// Finds recent clipboard activity.
    private func findRecentClipboardActivity() async -> [SecurityWarning] {
        let recentCopies = clipboardManager.recentCopies
        let now = Date()

        // Only show copies from last 24 hours
        let cutoff = Calendar.current.date(byAdding: .hour, value: -24, to: now)!

        let recent = recentCopies.filter { $0.copiedAt > cutoff }

        return recent.map { copy in
            let timeAgo = now.timeIntervalSince(copy.copiedAt)
            let minutesAgo = Int(timeAgo / 60)

            return SecurityWarning(
                id: UUID(),
                type: .recentlyCopied,
                keyID: copy.keyID,
                keyLabel: copy.keyLabel,
                message: "'\(copy.keyLabel)' copied \(formatTimeAgo(minutesAgo)) ago",
                severity: .low,
                date: copy.copiedAt
            )
        }
    }

    /// Formats time ago string.
    private func formatTimeAgo(_ minutes: Int) -> String {
        if minutes < 1 {
            return "just now"
        } else if minutes == 1 {
            return "1 minute"
        } else if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }
}

/// A security warning about a key or system state.
public struct SecurityWarning: Identifiable {
    public let id: UUID
    public let type: WarningType
    public let keyID: UUID
    public let keyLabel: String
    public let message: String
    public let severity: Severity
    public let date: Date

    public init(
        id: UUID,
        type: WarningType,
        keyID: UUID,
        keyLabel: String,
        message: String,
        severity: Severity,
        date: Date
    ) {
        self.id = id
        self.type = type
        self.keyID = keyID
        self.keyLabel = keyLabel
        self.message = message
        self.severity = severity
        self.date = date
    }
}

/// Type of security warning.
public enum WarningType {
    case expired
    case needsRotation
    case recentlyCopied
}

/// Severity level of a warning.
public enum Severity: Int {
    case high = 3
    case medium = 2
    case low = 1

    public var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "blue"
        }
    }

    public var icon: String {
        switch self {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        }
    }
}
