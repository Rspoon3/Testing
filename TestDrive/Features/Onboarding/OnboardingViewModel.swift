import Foundation

/// View model for the onboarding flow.
@Observable
final class OnboardingViewModel {
    var selectedAttitudes: Set<Attitude> = []

    private let healthKitService = HealthKitService()
    private let notificationService = NotificationService.shared
    private let userPreferences = UserPreferences.shared

    /// Whether at least one attitude is selected.
    var hasSelection: Bool {
        !selectedAttitudes.isEmpty
    }

    // MARK: - Public Helpers

    /// Saves the selected attitudes to user preferences.
    func saveAttitudes() {
        guard !selectedAttitudes.isEmpty else { return }
        userPreferences.selectedAttitudes = selectedAttitudes
    }

    /// Requests all necessary permissions (HealthKit and notifications).
    func requestPermissions() async {
        do {
            try await healthKitService.requestAuthorization()
        } catch {
            print("HealthKit authorization failed: \(error)")
        }

        await notificationService.requestPermission()
    }

    /// Marks onboarding as complete.
    func completeOnboarding() {
        userPreferences.hasCompletedOnboarding = true
    }
}
