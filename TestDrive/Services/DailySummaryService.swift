import Foundation
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "DailySummaryService")

/// Service for generating and scheduling daily summary notifications.
final class DailySummaryService {
    static let shared = DailySummaryService()

    private let healthKitService = HealthKitService()
    private let chatGPTService = ChatGPTService()
    private let notificationService = NotificationService.shared
    private let userPreferences = UserPreferences.shared

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Helpers

    /// Generates and schedules the morning summary notification.
    /// - Parameter hour: The hour to schedule the notification (default: 8 AM).
    func scheduleMorningSummary(hour: Int = 8) async {
        logger.info("🌅 Generating morning summary...")

        do {
            let message = try await generateMorningSummary()
            await notificationService.scheduleDailyNotification(
                identifier: NotificationService.morningSummaryID,
                title: "Good Morning! ☀️",
                body: message,
                hour: hour
            )
            logger.info("✅ Morning summary scheduled")
        } catch {
            logger.error("❌ Failed to generate morning summary: \(error.localizedDescription)")
        }
    }

    /// Generates and schedules the evening summary notification.
    /// - Parameter hour: The hour to schedule the notification (default: 9 PM).
    func scheduleEveningSummary(hour: Int = 21) async {
        logger.info("🌙 Generating evening summary...")

        do {
            let message = try await generateEveningSummary()
            await notificationService.scheduleDailyNotification(
                identifier: NotificationService.eveningSummaryID,
                title: "Daily Wrap-Up 🌙",
                body: message,
                hour: hour
            )
            logger.info("✅ Evening summary scheduled")
        } catch {
            logger.error("❌ Failed to generate evening summary: \(error.localizedDescription)")
        }
    }

    /// Schedules both morning and evening summary notifications based on user preferences.
    func scheduleDailySummaries() async {
        if userPreferences.morningSummaryEnabled {
            await scheduleMorningSummary(hour: userPreferences.morningSummaryHour)
        } else {
            // Cancel existing morning notification if disabled
            await notificationService.cancelNotification(identifier: NotificationService.morningSummaryID)
            logger.info("🌅 Morning summary disabled")
        }

        if userPreferences.eveningSummaryEnabled {
            await scheduleEveningSummary(hour: userPreferences.eveningSummaryHour)
        } else {
            // Cancel existing evening notification if disabled
            await notificationService.cancelNotification(identifier: NotificationService.eveningSummaryID)
            logger.info("🌙 Evening summary disabled")
        }
    }

    // MARK: - Private Helpers

    private func generateMorningSummary() async throws -> String {
        let workoutStats = try await healthKitService.fetchWorkoutStats()
        let weightStats = await healthKitService.fetchWeightStats()
        let userProfile = await healthKitService.fetchUserProfile()
        let streak = await healthKitService.fetchWorkoutStreak()
        let attitudes = userPreferences.selectedAttitudes

        return try await chatGPTService.generateMorningSummary(
            workoutStats: workoutStats,
            weightStats: weightStats,
            userProfile: userProfile,
            streak: streak,
            attitudes: attitudes
        )
    }

    private func generateEveningSummary() async throws -> String {
        let workoutStats = try await healthKitService.fetchWorkoutStats()
        let weightStats = await healthKitService.fetchWeightStats()
        let userProfile = await healthKitService.fetchUserProfile()
        let streak = await healthKitService.fetchWorkoutStreak()
        let attitudes = userPreferences.selectedAttitudes

        return try await chatGPTService.generateEveningSummary(
            workoutStats: workoutStats,
            weightStats: weightStats,
            userProfile: userProfile,
            streak: streak,
            attitudes: attitudes
        )
    }
}
