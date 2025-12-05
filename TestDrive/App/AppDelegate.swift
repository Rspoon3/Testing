import UIKit
import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "AppDelegate")

/// App delegate for handling HealthKit observer setup.
class AppDelegate: NSObject, UIApplicationDelegate {
    private var healthObserver: HealthObserver?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("🚀 App launched")

        setupHealthKitObserver()

        return true
    }

    // MARK: - Private Helpers

    private func setupHealthKitObserver() {
        logger.info("🏥 Setting up HealthKit observer...")

        // Use shared health store - must be same instance for background delivery
        let healthStore = HealthKitService.sharedHealthStore
        healthObserver = HealthObserver(healthStore: healthStore)

        // Set up callbacks before starting observer
        healthObserver?.onWorkoutDetected = { workout in
            logger.info("🏋️ Workout detected: \(workout.workoutActivityType.rawValue)")
            await BackgroundTaskService.shared.processWorkout(workout)
        }

        healthObserver?.onWeightDetected = { weightEntry in
            logger.info("⚖️ Weight detected: \(weightEntry.formattedWeight)")
            await BackgroundTaskService.shared.processWeightEntry(weightEntry)
        }

        Task {
            // Ensure authorization before enabling background delivery
            let healthKitService = HealthKitService()
            do {
                try await healthKitService.requestAuthorization()
                logger.info("✅ HealthKit authorization completed")
            } catch {
                logger.error("❌ HealthKit authorization failed: \(error.localizedDescription)")
            }

            // Schedule daily summary notifications with ChatGPT-generated content (8 AM and 9 PM)
            await DailySummaryService.shared.scheduleDailySummaries()
            logger.info("✅ Daily summary notifications scheduled")

            // Process all recent workouts and weight entries on app launch
            logger.info("📥 Processing all recent workouts...")
            await BackgroundTaskService.shared.processAllRecentWorkouts()

            logger.info("📥 Processing all recent weight entries...")
            await BackgroundTaskService.shared.processAllRecentWeightEntries()

            // Start observing (this will run indefinitely via AsyncStream)
            await healthObserver?.startObserving()
        }
    }
}
