import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "NotificationService")

/// Service for managing local notifications.
final class NotificationService: NSObject {
    static let shared = NotificationService()
    static let workoutIDKey = "workoutID"
    static let weightEntryIDKey = "weightEntryID"

    private let center = UNUserNotificationCenter.current()

    /// Callback when a notification is tapped with a workout ID.
    var onWorkoutNotificationTapped: ((String) -> Void)?

    /// Callback when a notification is tapped with a weight entry ID.
    var onWeightNotificationTapped: ((String) -> Void)?

    // MARK: - Initializer

    private override init() {
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
    ///   - workoutID: Optional workout ID for deep linking.
    ///   - delay: Seconds to wait before showing (default: 1).
    func scheduleNotification(
        title: String,
        body: String,
        workoutID: String? = nil,
        delay: TimeInterval = 1
    ) async {
        logger.info("📝 Scheduling notification - Title: \(title), Body length: \(body.count)")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let workoutID {
            content.userInfo = [Self.workoutIDKey: workoutID]
        }

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

    /// Schedules a local notification for a weight entry.
    /// - Parameters:
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - weightEntryID: The weight entry ID for deep linking.
    ///   - delay: Seconds to wait before showing (default: 1).
    func scheduleWeightNotification(
        title: String,
        body: String,
        weightEntryID: String,
        delay: TimeInterval = 1
    ) async {
        logger.info("📝 Scheduling weight notification - Title: \(title)")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [Self.weightEntryIDKey: weightEntryID]

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
            logger.info("✅ Weight notification scheduled successfully")
        } catch {
            logger.error("❌ Failed to schedule weight notification: \(error.localizedDescription)")
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
        let userInfo = response.notification.request.content.userInfo

        if let workoutID = userInfo[Self.workoutIDKey] as? String {
            logger.info("📲 Notification tapped for workout: \(workoutID)")
            onWorkoutNotificationTapped?(workoutID)
        } else if let weightEntryID = userInfo[Self.weightEntryIDKey] as? String {
            logger.info("📲 Notification tapped for weight entry: \(weightEntryID)")
            onWeightNotificationTapped?(weightEntryID)
        }

        completionHandler()
    }
}
