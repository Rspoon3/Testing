import Foundation
import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "ChatViewModel")

/// View model for ChatView handling message regeneration.
@Observable
final class ChatViewModel {
    var workoutMessage: WorkoutMessage
    var isRegenerating = false
    var errorMessage: String?

    private let healthKitService = HealthKitService()
    private let messageStore = WorkoutMessageStore.shared
    private let userPreferences = UserPreferences.shared

    // MARK: - Initializer

    init(workoutMessage: WorkoutMessage) {
        self.workoutMessage = workoutMessage
    }

    // MARK: - Public Helpers

    /// Regenerates the AI message using the selected provider.
    @MainActor
    func regenerateMessage() async {
        isRegenerating = true
        errorMessage = nil

        do {
            guard let workout = try await fetchWorkout(id: workoutMessage.workoutID) else {
                errorMessage = "Could not find original workout"
                isRegenerating = false
                return
            }

            let stats = try await healthKitService.fetchWorkoutStats()
            let userProfile = await healthKitService.fetchUserProfile()
            let previousWorkout = try? await healthKitService.fetchPreviousWorkout(before: workout)
            let heartRate = await healthKitService.fetchHeartRate(for: workout)
            let streak = await healthKitService.fetchWorkoutStreak()
            let attitudes = userPreferences.selectedAttitudes

            let aiService = AIServiceFactory.shared.currentService()

            logger.info("🔄 Regenerating message with provider: \(self.userPreferences.selectedAIProvider.rawValue)")

            let newMessageText = try await aiService.generateMessage(
                for: workout,
                stats: stats,
                userProfile: userProfile,
                lastWorkoutDate: previousWorkout?.endDate,
                heartRate: heartRate,
                streak: streak,
                attitudes: attitudes
            )

            let updatedMessage = WorkoutMessage(
                id: workoutMessage.id,
                workoutID: workoutMessage.workoutID,
                activityType: workoutMessage.activityType,
                activityName: workoutMessage.activityName,
                duration: workoutMessage.duration,
                calories: workoutMessage.calories,
                distance: workoutMessage.distance,
                message: newMessageText,
                attitudes: attitudes.map(\.rawValue).sorted().joined(separator: ", "),
                workoutDate: workoutMessage.workoutDate,
                createdAt: Date()
            )

            messageStore.update(updatedMessage)
            workoutMessage = updatedMessage

            logger.info("✅ Regenerated message for workout: \(self.workoutMessage.workoutID)")

        } catch {
            errorMessage = error.localizedDescription
            logger.error("❌ Failed to regenerate message: \(error.localizedDescription)")
        }

        isRegenerating = false
    }

    // MARK: - Private Helpers

    private func fetchWorkout(id: String) async throws -> HKWorkout? {
        let workouts = try await healthKitService.fetchRecentWorkouts()
        return workouts.first { $0.uuid.uuidString == id }
    }
}
