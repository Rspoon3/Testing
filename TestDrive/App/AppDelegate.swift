import UIKit
import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "AppDelegate")

/// App delegate for handling background tasks and HealthKit observer.
class AppDelegate: NSObject, UIApplicationDelegate {
    private var healthObserver: HealthObserver?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("🚀 App launched")

        // Setup HealthKit background delivery
        setupHealthKitObserver()

        return true
    }

    // MARK: - Private Helpers

    private func setupHealthKitObserver() {
        logger.info("🏥 Setting up HealthKit observer...")

        // Use shared health store - must be same instance for background delivery
        let healthStore = HealthKitService.sharedHealthStore
        healthObserver = HealthObserver(healthStore: healthStore)

        Task {
            do {
                // Ensure authorization before enabling background delivery
                let healthKitService = HealthKitService()
                try await healthKitService.requestAuthorization()
                logger.info("✅ HealthKit authorization completed")

                try await healthObserver?.enableBackgroundDelivery()
                logger.info("✅ Background delivery enabled")

                // Start observing BEFORE processing to catch any new data
                healthObserver?.startObserving()
                logger.info("✅ Health observer started")

                // Process all recent workouts and weight entries on app launch
                logger.info("📥 Processing all recent workouts...")
                await BackgroundTaskService.shared.processAllRecentWorkouts()

                logger.info("📥 Processing all recent weight entries...")
                await BackgroundTaskService.shared.processAllRecentWeightEntries()

                healthObserver?.onWorkoutDetected = { workout in
                    logger.info("🏋️ Workout detected: \(workout.workoutActivityType.rawValue)")
                    await BackgroundTaskService.shared.processWorkout(workout)
                }

                healthObserver?.onWeightDetected = { weightEntry in
                    logger.info("⚖️ Weight detected: \(weightEntry.formattedWeight)")
                    await BackgroundTaskService.shared.processWeightEntry(weightEntry)
                }
            } catch {
                logger.error("❌ Failed to setup HealthKit observer: \(error.localizedDescription)")
            }
        }
    }
}
