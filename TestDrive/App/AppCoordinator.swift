import SwiftUI

/// Manages the app's navigation state.
@Observable
final class AppCoordinator {
    var hasCompletedOnboarding: Bool
    var selectedWorkoutMessage: WorkoutMessage?

    // MARK: - Initializer

    init() {
        self.hasCompletedOnboarding = UserPreferences.shared.hasCompletedOnboarding
    }

    // MARK: - Public Helpers

    /// Marks onboarding as complete.
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserPreferences.shared.hasCompletedOnboarding = true
    }

    /// Navigates to a workout message by its workout ID.
    /// - Parameter workoutID: The workout UUID string.
    func navigateToWorkout(workoutID: String) {
        guard let message = WorkoutMessageStore.shared.message(forWorkoutID: workoutID) else {
            return
        }
        selectedWorkoutMessage = message
    }
}
