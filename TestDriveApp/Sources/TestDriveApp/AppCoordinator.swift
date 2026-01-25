import SwiftUI
import MomentumCore
import MomentumPersistence

/// Manages the app's navigation state.
@Observable
public final class AppCoordinator {
    public var hasCompletedOnboarding: Bool
    public var selectedWorkoutMessage: WorkoutMessage?
    public var selectedWeightMessage: WeightMessage?
    public var selectedDailySummaryMessage: DailySummaryMessage?

    // MARK: - Initializer

    public init() {
        self.hasCompletedOnboarding = UserPreferences.shared.hasCompletedOnboarding
    }

    // MARK: - Public Helpers

    /// Marks onboarding as complete.
    public func completeOnboarding() {
        hasCompletedOnboarding = true
        UserPreferences.shared.hasCompletedOnboarding = true
    }

    /// Navigates to a workout message by its workout ID.
    /// - Parameter workoutID: The workout UUID string.
    public func navigateToWorkout(workoutID: String) {
        guard let message = HealthEventStore.shared.workout(forWorkoutID: workoutID) else {
            return
        }
        selectedWorkoutMessage = message
    }

    /// Navigates to a weight message by its weight entry ID.
    /// - Parameter weightEntryID: The weight entry UUID string.
    public func navigateToWeightEntry(weightEntryID: String) {
        guard let message = HealthEventStore.shared.weight(forWeightEntryID: weightEntryID) else {
            return
        }
        selectedWeightMessage = message
    }

    /// Navigates to a daily summary message by its ID.
    /// - Parameter summaryID: The summary UUID string.
    public func navigateToDailySummary(summaryID: String) {
        guard let message = HealthEventStore.shared.summary(forID: summaryID) else {
            return
        }
        selectedDailySummaryMessage = message
    }

    /// Navigates to the most recent daily summary of the given type.
    /// - Parameter isMorning: True for morning summary, false for evening.
    public func navigateToLatestSummary(isMorning: Bool) {
        let summaries = HealthEventStore.shared.summaries()
        let targetType: SummaryType = isMorning ? .morning : .evening
        guard let message = summaries.first(where: { $0.summaryType == targetType }) else {
            return
        }
        selectedDailySummaryMessage = message
    }
}
