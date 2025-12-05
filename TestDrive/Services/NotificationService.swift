import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "NotificationService")

/// Service for managing local notifications.
final class NotificationService: NSObject {
    private let center = UNUserNotificationCenter.current()

    // MARK: - Initializer

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Public Helpers

    /// Requests notification permissions from the user.
    /// - Returns: Whether permission was granted.
    @discardableResult
    func requestPermission() async -> Bool {
        logger.info("🔔 Requesting notification permission...")
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            logger.info("✅ Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("❌ Notification permission error: \(error.localizedDescription)")
            return false
        }
    }

    /// Checks current notification authorization status.
    /// - Returns: The current authorization status.
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        logger.info("📊 Notification status: \(settings.authorizationStatus.rawValue)")
        return settings.authorizationStatus
    }

    /// Schedules a local notification.
    /// - Parameters:
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - delay: Seconds to wait before showing (default: 1).
    func scheduleNotification(
        title: String,
        body: String,
        delay: TimeInterval = 1
    ) async {
        logger.info("📝 Scheduling notification - Title: \(title)")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            logger.info("✅ Notification scheduled successfully")
        } catch {
            logger.error("❌ Failed to schedule notification: \(error.localizedDescription)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
