import Foundation
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "WeightChatViewModel")

/// View model for WeightChatView handling message regeneration.
@Observable
final class WeightChatViewModel {
    var weightMessage: WeightMessage
    var isRegenerating = false
    var errorMessage: String?

    private let healthKitService = HealthKitService()
    private let messageStore = WeightMessageStore.shared
    private let userPreferences = UserPreferences.shared

    // MARK: - Initializer

    init(weightMessage: WeightMessage) {
        self.weightMessage = weightMessage
    }

    // MARK: - Public Helpers

    /// Regenerates the AI message using the selected provider.
    @MainActor
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
            let attitudes = userPreferences.selectedAttitudes

            let aiService = AIServiceFactory.shared.currentService()

            logger.info("🔄 Regenerating weight message with provider: \(self.userPreferences.selectedAIProvider.rawValue)")

            let newMessageText = try await aiService.generateWeightMessage(
                for: weightEntry,
                weightStats: weightStats,
                workoutStats: workoutStats,
                userProfile: userProfile,
                streak: streak,
                attitudes: attitudes
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

            messageStore.update(updatedMessage)
            weightMessage = updatedMessage

            logger.info("✅ Regenerated message for weight entry: \(self.weightMessage.weightEntryID)")

        } catch {
            errorMessage = error.localizedDescription
            logger.error("❌ Failed to regenerate weight message: \(error.localizedDescription)")
        }

        isRegenerating = false
    }
}
