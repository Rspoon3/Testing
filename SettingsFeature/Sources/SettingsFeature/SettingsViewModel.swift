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
        // Test vaults with different numbers of credentials
        let testVaults: [(name: String, icon: String, color: String, credentialCount: Int)] = [
            ("Work APIs", "briefcase.fill", "#007AFF", 12),
            ("Development", "hammer.fill", "#34C759", 12),
            ("Production", "server.rack", "#FF3B30", 12),
            ("Testing", "flask.fill", "#FF9500", 8),
            ("Personal", "person.fill", "#AF52DE", 6),
            ("History Demo", "clock.arrow.circlepath", "#FF2D55", 0) // Special vault for history features
        ]

        // Define credential templates with multiple secrets (shared across all vaults)
        let credentialTemplates: [(
                label: String,
                secrets: [(label: String, value: String)],
                domain: String?,
                company: String?,
                env: APIEnvironment,
                tags: [String],
                notes: String,
                hasHistory: Bool
            )] = [
                // AWS Credentials (2 secrets)
                (
                    label: "AWS Production",
                    secrets: [
                        (label: "Access Key ID", value: "AKIA\(UUID().uuidString.prefix(16))"),
                        (label: "Secret Access Key", value: "wJalrXUtnFEMI/K7MDENG/bPxRfiCY\(UUID().uuidString.prefix(20))")
                    ],
                    domain: "aws.amazon.com",
                    company: "Amazon",
                    env: .production,
                    tags: ["aws", "cloud", "infrastructure"],
                    notes: "Production AWS credentials with full admin access. Rotate every 90 days.",
                    hasHistory: true
                ),
                // OAuth Client (2 secrets)
                (
                    label: "GitHub OAuth App",
                    secrets: [
                        (label: "Client ID", value: "Iv1.\(UUID().uuidString.prefix(16))"),
                        (label: "Client Secret", value: UUID().uuidString)
                    ],
                    domain: "github.com",
                    company: "GitHub",
                    env: .production,
                    tags: ["oauth", "auth", "github"],
                    notes: "OAuth credentials for GitHub app authentication. Callback URL: https://app.example.com/auth/callback",
                    hasHistory: false
                ),
                // Twitter API (5 secrets)
                (
                    label: "Twitter API",
                    secrets: [
                        (label: "API Key", value: UUID().uuidString),
                        (label: "API Secret", value: UUID().uuidString),
                        (label: "Bearer Token", value: "AAAAAAAAAAAAAAAAAAAAAA\(UUID().uuidString)"),
                        (label: "Access Token", value: "\(Int.random(in: 1000000000...9999999999))-\(UUID().uuidString)"),
                        (label: "Access Token Secret", value: UUID().uuidString)
                    ],
                    domain: "twitter.com",
                    company: "Twitter",
                    env: .production,
                    tags: ["twitter", "social", "api"],
                    notes: "Twitter API v2 credentials with read/write access. Rate limit: 500k tweets/month",
                    hasHistory: true
                ),
                // Stripe (3 secrets)
                (
                    label: "Stripe Payment",
                    secrets: [
                        (label: "Publishable Key", value: "pk_test_\(UUID().uuidString)"),
                        (label: "Secret Key", value: "sk_test_\(UUID().uuidString)"),
                        (label: "Webhook Secret", value: "whsec_\(UUID().uuidString)")
                    ],
                    domain: "stripe.com",
                    company: "Stripe",
                    env: .production,
                    tags: ["payments", "billing", "stripe"],
                    notes: "Stripe production keys with webhook endpoints configured. Webhooks: payment_intent.succeeded, charge.failed",
                    hasHistory: false
                ),
                // Database (2 secrets)
                (
                    label: "PostgreSQL Production",
                    secrets: [
                        (label: "Username", value: "prod_user_\(UUID().uuidString.prefix(8))"),
                        (label: "Password", value: UUID().uuidString + "!Aa1")
                    ],
                    domain: nil,
                    company: "PostgreSQL",
                    env: .production,
                    tags: ["database", "postgres", "sql"],
                    notes: "Production database credentials. Host: db.prod.example.com:5432. Read/Write access.",
                    hasHistory: true
                ),
                // Cloudflare (2 secrets)
                (
                    label: "Cloudflare R2",
                    secrets: [
                        (label: "API Key", value: UUID().uuidString),
                        (label: "S3 Endpoint URL", value: "https://\(UUID().uuidString.prefix(32)).r2.cloudflarestorage.com")
                    ],
                    domain: "cloudflare.com",
                    company: "Cloudflare",
                    env: .production,
                    tags: ["cdn", "storage", "cloudflare"],
                    notes: "R2 storage bucket for static assets and media files. Bucket: prod-assets",
                    hasHistory: false
                ),
                // SendGrid (1 secret)
                (
                    label: "SendGrid Email",
                    secrets: [
                        (label: "API Key", value: "SG.\(UUID().uuidString).\(UUID().uuidString)")
                    ],
                    domain: "sendgrid.com",
                    company: "SendGrid",
                    env: .production,
                    tags: ["email", "sendgrid", "notifications"],
                    notes: "Transactional email API. Rate limit: 100k emails/day. From: noreply@example.com",
                    hasHistory: false
                ),
                // Firebase (3 secrets)
                (
                    label: "Firebase Admin",
                    secrets: [
                        (label: "Project ID", value: "my-app-\(UUID().uuidString.prefix(8))"),
                        (label: "Private Key", value: "-----BEGIN PRIVATE KEY-----\n\(UUID().uuidString)\n-----END PRIVATE KEY-----"),
                        (label: "Client Email", value: "firebase-adminsdk-\(UUID().uuidString.prefix(5))@my-app.iam.gserviceaccount.com")
                    ],
                    domain: "firebase.google.com",
                    company: "Google",
                    env: .production,
                    tags: ["firebase", "backend", "google"],
                    notes: "Firebase Admin SDK credentials for server-side operations. Full admin access.",
                    hasHistory: true
                ),
                // Slack (1 secret)
                (
                    label: "Slack Bot",
                    secrets: [
                        (label: "Bot Token", value: "xoxb-\(Int.random(in: 1000000000...9999999999))-\(Int.random(in: 1000000000...9999999999))-\(UUID().uuidString)")
                    ],
                    domain: "slack.com",
                    company: "Slack",
                    env: .production,
                    tags: ["slack", "chat", "notifications"],
                    notes: "Slack bot for #engineering channel notifications. Scopes: chat:write, files:write",
                    hasHistory: false
                ),
                // Twilio (2 secrets)
                (
                    label: "Twilio SMS",
                    secrets: [
                        (label: "Account SID", value: "AC\(UUID().uuidString)"),
                        (label: "Auth Token", value: UUID().uuidString)
                    ],
                    domain: "twilio.com",
                    company: "Twilio",
                    env: .production,
                    tags: ["sms", "twilio", "notifications"],
                    notes: "SMS notification service. Phone: +1 (555) 123-4567. Rate: $0.0075/SMS",
                    hasHistory: false
                ),
                // MongoDB (1 secret)
                (
                    label: "MongoDB Atlas",
                    secrets: [
                        (label: "Connection String", value: "mongodb+srv://user:\(UUID().uuidString)@cluster0.example.mongodb.net/mydb?retryWrites=true&w=majority")
                    ],
                    domain: nil,
                    company: "MongoDB",
                    env: .production,
                    tags: ["database", "mongodb", "nosql"],
                    notes: "MongoDB Atlas production cluster. Region: US-East-1. Tier: M10",
                    hasHistory: true
                ),
                // Redis (1 secret)
                (
                    label: "Redis Cache",
                    secrets: [
                        (label: "Password", value: UUID().uuidString + "!Rr1")
                    ],
                    domain: nil,
                    company: "Redis",
                    env: .production,
                    tags: ["cache", "redis", "database"],
                    notes: "Redis cache instance. Host: redis.prod.example.com:6379. Max memory: 2GB",
                    hasHistory: false
                )
            ]

        // Loop through each vault and create it with credentials
        for testVault in testVaults {
            // Create vault
            let vault = try await vaultManager.createVault(
                name: testVault.name,
                iconName: testVault.icon,
                colorHex: testVault.color
            )

            // Create credentials up to the specified count
            for i in 0..<min(testVault.credentialCount, credentialTemplates.count) {
                let template = credentialTemplates[i]

                // Generate fresh secret values for each credential (not reusing template values)
                let freshSecrets: [(label: String, value: String)] = template.secrets.map { secretTemplate in
                    let freshValue: String
                    switch secretTemplate.label {
                    case "Access Key ID":
                        freshValue = "AKIA\(UUID().uuidString.prefix(16).uppercased())"
                    case "Secret Access Key":
                        freshValue = "wJalrXUtnFEMI/K7MDENG/bPxRfiCY\(UUID().uuidString.prefix(20))"
                    case "Client ID":
                        freshValue = "Iv1.\(UUID().uuidString.prefix(16))"
                    case "API Key", "Client Secret", "API Secret", "Auth Token":
                        freshValue = UUID().uuidString
                    case "Bearer Token":
                        freshValue = "AAAAAAAAAAAAAAAAAAAAAA\(UUID().uuidString)"
                    case "Access Token":
                        freshValue = "\(Int.random(in: 1000000000...9999999999))-\(UUID().uuidString)"
                    case "Access Token Secret":
                        freshValue = UUID().uuidString
                    case "Publishable Key":
                        freshValue = "pk_live_\(UUID().uuidString)"
                    case "Secret Key":
                        freshValue = "sk_live_\(UUID().uuidString)"
                    case "Webhook Secret":
                        freshValue = "whsec_\(UUID().uuidString)"
                    case "Username":
                        freshValue = "user_\(UUID().uuidString.prefix(8))"
                    case "Password":
                        freshValue = "\(UUID().uuidString)!Aa1"
                    case "Bot Token":
                        freshValue = "xoxb-\(Int.random(in: 1000000000...9999999999))-\(Int.random(in: 1000000000...9999999999))-\(UUID().uuidString)"
                    case "Account SID":
                        freshValue = "AC\(UUID().uuidString)"
                    case "Connection String":
                        freshValue = "mongodb+srv://user:\(UUID().uuidString)@cluster0.example.mongodb.net/mydb?retryWrites=true&w=majority"
                    case "Project ID":
                        freshValue = "proj-\(UUID().uuidString.prefix(8))"
                    case "Private Key":
                        freshValue = "-----BEGIN PRIVATE KEY-----\n\(UUID().uuidString)\n-----END PRIVATE KEY-----"
                    case "Client Email":
                        freshValue = "firebase-\(UUID().uuidString.prefix(5))@proj.iam.gserviceaccount.com"
                    case "S3 Endpoint URL":
                        freshValue = "https://\(UUID().uuidString.prefix(32)).r2.cloudflarestorage.com"
                    default:
                        freshValue = UUID().uuidString
                    }
                    return (label: secretTemplate.label, value: freshValue)
                }

                let credentialWithSecrets = try await credentialManager.createCredential(
                    label: template.label,
                    secrets: freshSecrets,
                    vaultID: vault.id,
                    websiteDomain: template.domain,
                    company: template.company,
                    environment: template.env,
                    tags: template.tags,
                    notes: template.notes,
                    rotateAt: Date().addingTimeInterval(TimeInterval.random(in: 0...(90 * 24 * 60 * 60)))
                )

                // Add history for some credentials (simplified to avoid errors)
                if template.hasHistory && i < 6 {  // Only add history to first 6 credentials per vault
                    do {
                        let firstSecret = freshSecrets[0]

                        // Create 1-2 history entries (not too many to avoid issues)
                        let historyCount = Int.random(in: 1...2)
                        for j in 1...historyCount {
                            let reason: RotationReason = (j == historyCount) ? .rotated : .compromised

                            try await credentialManager.updateSecret(
                                for: credentialWithSecrets.credential,
                                label: firstSecret.label,
                                newValue: "\(UUID().uuidString)_v\(j)",
                                reason: reason
                            )
                        }

                        // Mark some secrets as expired (every 4th credential)
                        if i % 4 == 0 {
                            let expiredDate = Date().addingTimeInterval(-TimeInterval.random(in: (7 * 24 * 60 * 60)...(30 * 24 * 60 * 60)))
                            try await credentialManager.updateSecret(
                                for: credentialWithSecrets.credential,
                                label: firstSecret.label,
                                newValue: UUID().uuidString,
                                reason: .expired,
                                expiresAt: expiredDate
                            )
                        }

                        // Revoke some secrets (every 5th credential with 2+ secrets)
                        if i % 5 == 0 && credentialWithSecrets.secrets.count > 1 {
                            let secondSecret = credentialWithSecrets.secrets[1]
                            try await credentialManager.revokeSecret(
                                for: credentialWithSecrets.credential,
                                label: secondSecret.secretLabel,
                                reason: "Security audit - credential no longer needed"
                            )
                        }
                    } catch {
                        // Log error but continue creating other credentials
                        print("Warning: Failed to add history for credential \(template.label): \(error)")
                    }
                }
            }

            // Special handling for "History Demo" vault
            if testVault.name == "History Demo" {
                // Credential 1: Frequently Rotated API Key (5 rotations)
                let rotatedCred = try await credentialManager.createCredential(
                    label: "Frequently Rotated API Key",
                    secrets: [
                        (label: "API Key", value: UUID().uuidString)
                    ],
                    vaultID: vault.id,
                    websiteDomain: "api.example.com",
                    company: "Example Corp",
                    environment: .production,
                    tags: ["api", "rotated", "frequent"],
                    notes: "API key that gets rotated monthly. Currently on version 6. Last rotation was routine maintenance.",
                    rotateAt: Date().addingTimeInterval(30 * 24 * 60 * 60) // Rotate in 30 days
                )

                // Create 5 rotation history entries
                for j in 1...5 {
                    let reason: RotationReason
                    switch j {
                    case 1: reason = .compromised
                    case 2: reason = .userInitiated
                    case 3: reason = .expired
                    case 4: reason = .rotated
                    case 5: reason = .rotated
                    default: reason = .userInitiated
                    }

                    try await credentialManager.updateSecret(
                        for: rotatedCred.credential,
                        label: "API Key",
                        newValue: UUID().uuidString,
                        reason: reason
                    )
                }

                // Credential 2: Expired Database Credentials (expired 15 days ago)
                let expiredCred = try await credentialManager.createCredential(
                    label: "Expired Database Access",
                    secrets: [
                        (label: "Username", value: "db_user_expired"),
                        (label: "Password", value: UUID().uuidString)
                    ],
                    vaultID: vault.id,
                    websiteDomain: nil,
                    company: "Internal DB",
                    environment: .staging,
                    tags: ["database", "expired", "needs-rotation"],
                    notes: "Staging database credentials that expired 15 days ago. Needs immediate rotation!",
                    rotateAt: Date().addingTimeInterval(-15 * 24 * 60 * 60) // Expired 15 days ago
                )

                // Add history and mark as expired
                try await credentialManager.updateSecret(
                    for: expiredCred.credential,
                    label: "Password",
                    newValue: UUID().uuidString,
                    reason: .userInitiated
                )

                try await credentialManager.updateSecret(
                    for: expiredCred.credential,
                    label: "Password",
                    newValue: UUID().uuidString,
                    reason: .expired,
                    expiresAt: Date().addingTimeInterval(-15 * 24 * 60 * 60) // Set expiration 15 days ago
                )

                // Credential 3: OAuth Credentials with Revoked Secret
                let revokedCred = try await credentialManager.createCredential(
                    label: "OAuth with Revoked Secret",
                    secrets: [
                        (label: "Client ID", value: "client_\(UUID().uuidString.prefix(16))"),
                        (label: "Client Secret", value: UUID().uuidString)
                    ],
                    vaultID: vault.id,
                    websiteDomain: "oauth.example.com",
                    company: "OAuth Provider",
                    environment: .production,
                    tags: ["oauth", "revoked", "security-incident"],
                    notes: "OAuth credentials. Client Secret was revoked after security audit found it exposed in logs.",
                    rotateAt: nil
                )

                // Add some history to Client Secret
                try await credentialManager.updateSecret(
                    for: revokedCred.credential,
                    label: "Client Secret",
                    newValue: UUID().uuidString,
                    reason: .rotated
                )

                try await credentialManager.updateSecret(
                    for: revokedCred.credential,
                    label: "Client Secret",
                    newValue: UUID().uuidString,
                    reason: .userInitiated
                )

                // Revoke the Client Secret
                try await credentialManager.revokeSecret(
                    for: revokedCred.credential,
                    label: "Client Secret",
                    reason: "Found exposed in application logs during security audit on 2026-01-25. Immediately revoked and rotated."
                )

                // Credential 4: AWS Keys with Mixed History
                let awsCred = try await credentialManager.createCredential(
                    label: "AWS Keys (Mixed History)",
                    secrets: [
                        (label: "Access Key ID", value: "AKIA\(UUID().uuidString.prefix(16).uppercased())"),
                        (label: "Secret Access Key", value: UUID().uuidString)
                    ],
                    vaultID: vault.id,
                    websiteDomain: "aws.amazon.com",
                    company: "Amazon",
                    environment: .production,
                    tags: ["aws", "cloud", "history"],
                    notes: "AWS credentials showing various rotation scenarios. Access Key was compromised once, Secret Key rotated twice.",
                    rotateAt: Date().addingTimeInterval(60 * 24 * 60 * 60) // Rotate in 60 days
                )

                // Access Key ID history: compromised, then rotated
                try await credentialManager.updateSecret(
                    for: awsCred.credential,
                    label: "Access Key ID",
                    newValue: "AKIA\(UUID().uuidString.prefix(16).uppercased())",
                    reason: .compromised
                )

                try await credentialManager.updateSecret(
                    for: awsCred.credential,
                    label: "Access Key ID",
                    newValue: "AKIA\(UUID().uuidString.prefix(16).uppercased())",
                    reason: .rotated
                )

                // Secret Access Key history: rotated twice
                try await credentialManager.updateSecret(
                    for: awsCred.credential,
                    label: "Secret Access Key",
                    newValue: UUID().uuidString,
                    reason: .rotated
                )

                try await credentialManager.updateSecret(
                    for: awsCred.credential,
                    label: "Secret Access Key",
                    newValue: UUID().uuidString,
                    reason: .rotated
                )

                // Credential 5: Compromise Recovery (multiple incidents)
                let compromisedCred = try await credentialManager.createCredential(
                    label: "Multiple Security Incidents",
                    secrets: [
                        (label: "API Token", value: UUID().uuidString)
                    ],
                    vaultID: vault.id,
                    websiteDomain: "api.vulnerable.example",
                    company: "High Risk Service",
                    environment: .production,
                    tags: ["security", "compromised", "high-risk"],
                    notes: "Service with history of security issues. Token compromised twice, rotated multiple times as precaution.",
                    rotateAt: Date().addingTimeInterval(14 * 24 * 60 * 60) // Rotate in 2 weeks
                )

                // Create incident history
                try await credentialManager.updateSecret(
                    for: compromisedCred.credential,
                    label: "API Token",
                    newValue: UUID().uuidString,
                    reason: .compromised
                )

                try await credentialManager.updateSecret(
                    for: compromisedCred.credential,
                    label: "API Token",
                    newValue: UUID().uuidString,
                    reason: .rotated
                )

                try await credentialManager.updateSecret(
                    for: compromisedCred.credential,
                    label: "API Token",
                    newValue: UUID().uuidString,
                    reason: .compromised
                )

                try await credentialManager.updateSecret(
                    for: compromisedCred.credential,
                    label: "API Token",
                    newValue: UUID().uuidString,
                    reason: .rotated
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
