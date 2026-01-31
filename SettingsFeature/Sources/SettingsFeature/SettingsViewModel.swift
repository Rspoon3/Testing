import Dependencies
import Foundation
import GRDB
import SQLiteData
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

    @ObservationIgnored @Dependency(\.defaultDatabase) private var database
    private let vaultManager: VaultManager
    private let clipboardManager: ClipboardManager
    private let credentialManager: CredentialManager

    // MARK: - Initializer

    /// Creates a new settings view model.
    ///
    /// - Parameters:
    ///   - vaultManager: The vault manager for vault operations.
    ///   - clipboardManager: The clipboard manager for configuration.
    ///   - credentialManager: The credential manager for key operations.
    public init(
        vaultManager: VaultManager,
        clipboardManager: ClipboardManager,
        credentialManager: CredentialManager
    ) {
        self.vaultManager = vaultManager
        self.clipboardManager = clipboardManager
        self.credentialManager = credentialManager

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
            clipboardManager.clearClipboard()

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
                    // db.query(Credential.self).filter(\.vaultID == vault.id).all()
                    return [Credential]() // Placeholder
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

    #if DEBUG
    /// Populates database with test data for debugging.
    public func populateTestData() async throws {
        // Test vaults with different numbers of keys
        let testVaults: [(name: String, icon: String, color: String, keyCount: Int)] = [
            ("Work APIs", "briefcase.fill", "#007AFF", 1),
            ("Development", "hammer.fill", "#34C759", 5),
            ("Production", "server.rack", "#FF3B30", 10),
            ("Testing", "flask.fill", "#FF9500", 15),
            ("Personal", "person.fill", "#AF52DE", 20)
        ]

        for testVault in testVaults {
            // Create vault
            let vault = try await vaultManager.createVault(
                name: testVault.name,
                iconName: testVault.icon,
                colorHex: testVault.color
            )

            // Create keys for this vault
            for i in 1...testVault.keyCount {
                let domains = ["github.com", "stripe.com", "aws.amazon.com", "firebase.google.com", "heroku.com"]
                let companies = ["GitHub", "Stripe", "Amazon", "Google", "Salesforce"]
                let environments: [APIEnvironment] = [.production, .development, .staging, .testing]

                let notesOptions = [
                    "Used for CI/CD deployments and automated workflows. Rate limit: 5000 req/hour",
                    "Payment processing credential with webhook endpoints configured. Expires: Q2 2026",
                    "OAuth credentials for third-party integration. Restricted to US-East-1 region",
                    "Service account key for analytics dashboard. Read-only access to production data",
                    "API token for monitoring and alerting services. Auto-generated on 2024-12-15",
                    "Webhook secret for real-time event processing. Rotate every 90 days",
                    "Client credentials for mobile app authentication. Scopes: read, write, admin",
                    "Legacy credential - migrate to OAuth2 before end of quarter. Deprecated",
                    "Emergency access key - only use for production incidents. Notify team lead",
                    "Integration key for Slack notifications and team alerts. Channel: #engineering"
                ]

                let tagOptions = [
                    ["ci-cd", "automation"],
                    ["payments", "billing", "webhook"],
                    ["oauth", "auth", "integration"],
                    ["analytics", "readonly"],
                    ["monitoring", "alerts"],
                    ["webhook", "events", "realtime"],
                    ["mobile", "ios", "android"],
                    ["legacy", "deprecated", "migration"],
                    ["emergency", "oncall", "critical"],
                    ["slack", "notifications", "team"],
                    ["api", "rest"],
                    ["database", "storage"],
                    ["cdn", "media"],
                    ["email", "sendgrid"],
                    ["sms", "twilio"]
                ]

                let domainIndex = i % domains.count
                let envIndex = i % environments.count
                let notesIndex = i % notesOptions.count
                let tagsIndex = i % tagOptions.count

                let secret = "test_secret_\(UUID().uuidString.prefix(8))"
                let company = companies[domainIndex]
                let environment = environments[envIndex]

                // Create descriptive label with company and environment
                let label = "\(company) \(environment.rawValue.capitalized)"

                try await credentialManager.createKey(
                    label: label,
                    secret: secret,
                    vaultID: vault.id,
                    websiteDomain: domains[domainIndex],
                    company: company,
                    environment: environment,
                    tags: tagOptions[tagsIndex],
                    notes: notesOptions[notesIndex]
                )
            }
        }
    }
    #endif
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
