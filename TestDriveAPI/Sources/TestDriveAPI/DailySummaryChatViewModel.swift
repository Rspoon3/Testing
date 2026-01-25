import Foundation
import os.log
import MomentumCore
import MomentumNetworking
import MomentumHealth
import MomentumPersistence
import MomentumAI

private let logger = Logger(subsystem: "com.rspoon3.Momentum", category: "DailySummaryChatViewModel")

/// View model for DailySummaryChatView handling message regeneration.
@MainActor
@Observable
final class DailySummaryChatViewModel {
    var summaryMessage: DailySummaryMessage
    var isRegenerating = false
    var errorMessage: String?

    private let healthKitService = HealthKitService()
    private let eventStore = HealthEventStore.shared
    private let userPreferences = UserPreferences.shared

    // MARK: - Initializer

    init(summaryMessage: DailySummaryMessage) {
        self.summaryMessage = summaryMessage
    }

    // MARK: - Public Helpers

#if DEBUG
    /// Regenerates the AI message using the selected provider.
    func regenerateMessage() async {
        isRegenerating = true
        errorMessage = nil

        do {
            let workoutStats = try await healthKitService.fetchWorkoutStats()
            let weightStats = await healthKitService.fetchWeightStats()
            let userProfile = await healthKitService.fetchUserProfile()
            let streak = await healthKitService.fetchWorkoutStreak()
            let stepStats = await healthKitService.fetchStepStats()
            let attitudes = userPreferences.selectedAttitudes

            let aiService = AIServiceFactory.shared.currentService()

            logger.info("Regenerating \(self.summaryMessage.summaryType.rawValue) summary with provider: \(self.userPreferences.selectedAIProvider.rawValue)")

            let newMessageText: String
            switch summaryMessage.summaryType {
            case .morning:
                newMessageText = try await aiService.generateMorningSummary(
                    workoutStats: workoutStats,
                    weightStats: weightStats,
                    userProfile: userProfile,
                    streak: streak,
                    attitudes: attitudes,
                    stepStats: stepStats
                )
            case .evening:
                newMessageText = try await aiService.generateEveningSummary(
                    workoutStats: workoutStats,
                    weightStats: weightStats,
                    userProfile: userProfile,
                    streak: streak,
                    attitudes: attitudes,
                    stepStats: stepStats
                )
            }

            let updatedMessage = DailySummaryMessage(
                id: summaryMessage.id,
                summaryType: summaryMessage.summaryType,
                message: newMessageText,
                attitudes: attitudes.map(\.rawValue).sorted().joined(separator: ", "),
                summaryDate: summaryMessage.summaryDate,
                createdAt: Date()
            )

            eventStore.update(updatedMessage)
            summaryMessage = updatedMessage

            logger.info("Regenerated \(self.summaryMessage.summaryType.rawValue) summary")

        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to regenerate summary: \(error.localizedDescription)")
        }

        isRegenerating = false
    }
#endif
}
