import Foundation
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "DailySummaryService")

/// Service for generating and scheduling daily summary notifications.
final class DailySummaryService {
    static let shared = DailySummaryService()

    private let healthKitService = HealthKitService()
    private let notificationService = NotificationService.shared
    private let userPreferences = UserPreferences.shared
    private let messageStore = DailySummaryMessageStore.shared

    /// Returns the AI service based on user preferences.
    private var aiService: AIMessageService {
        AIServiceFactory.shared.currentService()
    }

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Helpers

    /// Generates and schedules the morning summary notification.
    /// - Parameter hour: The hour to schedule the notification (default: 8 AM).
    func scheduleMorningSummary(hour: Int = 8) async {
        logger.info("🌅 Generating morning summary...")

        do {
            let message = try await generateMorningSummary()

            // Save to activity list
            let summaryMessage = DailySummaryMessage(
                summaryType: .morning,
                message: message,
                attitudes: userPreferences.selectedAttitudes.map(\.rawValue).sorted().joined(separator: ", "),
                summaryDate: Date()
            )
            messageStore.save(summaryMessage)

            // Schedule notification
            await notificationService.scheduleDailyNotification(
                identifier: NotificationService.morningSummaryID,
                title: "Good Morning!",
                body: message,
                hour: hour
            )
            logger.info("✅ Morning summary saved and scheduled")
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

            // Save to activity list
            let summaryMessage = DailySummaryMessage(
                summaryType: .evening,
                message: message,
                attitudes: userPreferences.selectedAttitudes.map(\.rawValue).sorted().joined(separator: ", "),
                summaryDate: Date()
            )
            messageStore.save(summaryMessage)

            // Schedule notification
            await notificationService.scheduleDailyNotification(
                identifier: NotificationService.eveningSummaryID,
                title: "Daily Wrap-Up",
                body: message,
                hour: hour
            )
            logger.info("✅ Evening summary saved and scheduled")
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

        return try await aiService.generateMorningSummary(
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

        return try await aiService.generateEveningSummary(
            workoutStats: workoutStats,
            weightStats: weightStats,
            userProfile: userProfile,
            streak: streak,
            attitudes: attitudes
        )
    }
}
