import Foundation
import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// View model for the settings screen.
///
/// Manages app configuration including clipboard settings, theme preferences,
/// and data management operations.
@MainActor
@Observable
public final class SettingsViewModel {

    // MARK: - Settings Properties

    /// Duration in seconds before clipboard auto-clears.
    public var autoClearDuration: Int {
        get { UserDefaults.standard.integer(forKey: "clipboardAutoClearDuration") }
        set { UserDefaults.standard.set(newValue, forKey: "clipboardAutoClearDuration") }
    }

    /// Whether clipboard notifications are enabled.
    public var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "clipboardNotificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "clipboardNotificationsEnabled") }
    }

    /// Selected color scheme (system, light, dark).
    public var colorScheme: String {
        get { UserDefaults.standard.string(forKey: "colorScheme") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "colorScheme") }
    }

    // MARK: - State Properties

    public var isClearing = false
    public var isExporting = false
    public var errorMessage: String?
    public var showingClearConfirmation = false
    public var exportURL: URL?

    private let database: DatabaseManager
    private let vaultManager: VaultManager
    private let clipboardManager: ClipboardManager

    // MARK: - Initializer

    /// Creates a new settings view model.
    ///
    /// - Parameters:
    ///   - database: The database manager for data operations.
    ///   - vaultManager: The vault manager for vault operations.
    ///   - clipboardManager: The clipboard manager for configuration.
    public init(
        database: DatabaseManager,
        vaultManager: VaultManager,
        clipboardManager: ClipboardManager
    ) {
        self.database = database
        self.vaultManager = vaultManager
        self.clipboardManager = clipboardManager

        // Set defaults if not set
        if UserDefaults.standard.object(forKey: "clipboardAutoClearDuration") == nil {
            UserDefaults.standard.set(30, forKey: "clipboardAutoClearDuration")
        }
        if UserDefaults.standard.object(forKey: "clipboardNotificationsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "clipboardNotificationsEnabled")
        }

        // Sync clipboard settings
        clipboardManager.autoClearDuration = TimeInterval(autoClearDuration)
        clipboardManager.notificationsEnabled = notificationsEnabled
    }

    // MARK: - Public Helpers

    /// Updates clipboard auto-clear duration.
    ///
    /// - Parameter duration: The new duration in seconds.
    public func updateAutoClearDuration(_ duration: Int) {
        autoClearDuration = duration
        clipboardManager.autoClearDuration = TimeInterval(duration)
    }

    /// Updates clipboard notification setting.
    ///
    /// - Parameter enabled: Whether notifications are enabled.
    public func updateNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        clipboardManager.notificationsEnabled = enabled
    }

    /// Clears all app data with confirmation.
    public func clearAllData() async throws {
        guard !isClearing else { return }

        isClearing = true
        errorMessage = nil

        do {
            // Delete all vaults (cascades to keys)
            let vaults = try await vaultManager.fetchAllVaults()
            for vault in vaults {
                try await vaultManager.deleteVault(vault)
            }

            // Clear clipboard
            await clipboardManager.clearClipboard()

            // Clear recent copies
            clipboardManager.recentCopies = []

        } catch {
            errorMessage = "Failed to clear data: \(error.localizedDescription)"
            throw error
        }

        isClearing = false
    }

    /// Exports all data to a JSON file.
    ///
    /// - Returns: URL to the exported file.
    public func exportData() async throws -> URL {
        guard !isExporting else { throw ExportError.alreadyExporting }

        isExporting = true
        errorMessage = nil

        do {
            // Fetch all vaults
            let vaults = try await vaultManager.fetchAllVaults()

            // Create export data structure
            var exportData: [String: Any] = [
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "vaults": []
            ]

            var vaultsData: [[String: Any]] = []

            for vault in vaults {
                var vaultData: [String: Any] = [
                    "id": vault.id.uuidString,
                    "name": vault.name,
                    "iconName": vault.iconName,
                    "colorHex": vault.colorHex,
                    "createdAt": ISO8601DateFormatter().string(from: vault.createdAt)
                ]

                // Fetch keys for this vault (without secrets)
                // Note: Secrets are NOT exported for security
                let keys = try await database.read { _ in
                    // db.query(APIKey.self).filter(\.vaultID == vault.id).all()
                    return [APIKey]() // Placeholder
                }

                let keysData = keys.map { key in
                    [
                        "label": key.label,
                        "domain": key.websiteDomain ?? "",
                        "company": key.company ?? "",
                        "environment": key.environment.rawValue,
                        "tags": key.tags,
                        "notes": key.notes,
                        "createdAt": ISO8601DateFormatter().string(from: key.createdAt)
                    ] as [String: Any]
                }

                vaultData["keys"] = keysData
                vaultsData.append(vaultData)
            }

            exportData["vaults"] = vaultsData

            // Write to temporary file
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)

            let tempDir = FileManager.default.temporaryDirectory
            let filename = "testdrive-export-\(ISO8601DateFormatter().string(from: Date())).json"
            let fileURL = tempDir.appendingPathComponent(filename)

            try jsonData.write(to: fileURL)

            exportURL = fileURL
            isExporting = false
            return fileURL

        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            isExporting = false
            throw error
        }
    }

    /// Gets the selected color scheme as SwiftUI ColorScheme.
    public func selectedColorScheme() -> ColorScheme? {
        switch colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // System
        }
    }
}

/// Export-related errors.
enum ExportError: LocalizedError {
    case alreadyExporting

    var errorDescription: String? {
        switch self {
        case .alreadyExporting:
            return "An export is already in progress"
        }
    }
}
