import SwiftUI

/// Manages the app's navigation state.
@Observable
final class AppCoordinator {
    var hasCompletedOnboarding: Bool

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
}
