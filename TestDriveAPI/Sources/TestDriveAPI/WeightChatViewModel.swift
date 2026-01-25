import Foundation
import os.log
import MomentumCore
import MomentumNetworking
import MomentumHealth
import MomentumPersistence
import MomentumAI

private let logger = Logger(subsystem: "com.rspoon3.Momentum", category: "WeightChatViewModel")

/// View model for WeightChatView handling message regeneration.
@MainActor
@Observable
final class WeightChatViewModel {
    var weightMessage: WeightMessage
    var isRegenerating = false
    var errorMessage: String?

    private let healthKitService = HealthKitService()
    private let eventStore = HealthEventStore.shared
    private let userPreferences = UserPreferences.shared

    // MARK: - Initializer

    init(weightMessage: WeightMessage) {
        self.weightMessage = weightMessage
    }

    // MARK: - Public Helpers

#if DEBUG
    /// Regenerates the AI message using the selected provider.
    func regenerateMessage() async {
        isRegenerating = true
        errorMessage = nil

        do {
            let weightEntry = WeightEntry(
                id: weightMessage.weightEntryID,
                weightInPounds: weightMessage.weightInPounds,
                date: weightMessage.entryDate
            )

            let weightStats = await healthKitService.fetchWeightStats()
            let workoutStats = try await healthKitService.fetchWorkoutStats()
            let userProfile = await healthKitService.fetchUserProfile()
            let streak = await healthKitService.fetchWorkoutStreak()
            let stepStats = await healthKitService.fetchStepStats()
            let attitudes = userPreferences.selectedAttitudes

            let aiService = AIServiceFactory.shared.currentService()

            logger.info("Regenerating weight message with provider: \(self.userPreferences.selectedAIProvider.rawValue)")

            let newMessageText = try await aiService.generateWeightMessage(
                for: weightEntry,
                weightStats: weightStats,
                workoutStats: workoutStats,
                userProfile: userProfile,
                streak: streak,
                attitudes: attitudes,
                stepStats: stepStats
            )

            let updatedMessage = WeightMessage(
                id: weightMessage.id,
                weightEntryID: weightMessage.weightEntryID,
                weightInPounds: weightMessage.weightInPounds,
                message: newMessageText,
                attitudes: attitudes.map(\.rawValue).sorted().joined(separator: ", "),
                entryDate: weightMessage.entryDate,
                createdAt: Date()
            )

            eventStore.update(updatedMessage)
            weightMessage = updatedMessage

            logger.info("Regenerated message for weight entry: \(self.weightMessage.weightEntryID)")

        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to regenerate weight message: \(error.localizedDescription)")
        }

        isRegenerating = false
    }
    #endif
}
