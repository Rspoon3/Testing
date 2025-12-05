import UIKit
import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "AppDelegate")
private let debugLogger = DebugLogger.shared

/// App delegate for handling HealthKit observer setup.
class AppDelegate: NSObject, UIApplicationDelegate {
    private var healthObserver: HealthObserver?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("🚀 App launched")
        debugLogger.log("APP LAUNCHED - didFinishLaunchingWithOptions", category: .app)

        setupHealthKitObserver()

        return true
    }

    // MARK: - Private Helpers

    private func setupHealthKitObserver() {
        logger.info("🏥 Setting up HealthKit observer...")
        debugLogger.log("Setting up HealthKit observer...", category: .app)

        // Use shared health store - must be same instance for background delivery
        let healthStore = HealthKitService.sharedHealthStore
        healthObserver = HealthObserver(healthStore: healthStore)

        // Set up callbacks before starting observer
        healthObserver?.onWorkoutDetected = { workout in
            logger.info("🏋️ Workout detected: \(workout.workoutActivityType.rawValue)")
            debugLogger.log("onWorkoutDetected callback - type: \(workout.workoutActivityType.rawValue), uuid: \(workout.uuid)", category: .workout)
            await BackgroundTaskService.shared.processWorkout(workout)
        }

        healthObserver?.onWeightDetected = { weightEntry in
            logger.info("⚖️ Weight detected: \(weightEntry.formattedWeight)")
            debugLogger.log("onWeightDetected callback - weight: \(weightEntry.formattedWeight), id: \(weightEntry.id)", category: .weight)
            await BackgroundTaskService.shared.processWeightEntry(weightEntry)
        }

        Task {
            // Ensure authorization before enabling background delivery
            let healthKitService = HealthKitService()
            do {
                try await healthKitService.requestAuthorization()
                logger.info("✅ HealthKit authorization completed")
                debugLogger.log("HealthKit authorization completed successfully", category: .app)
            } catch {
                logger.error("❌ HealthKit authorization failed: \(error.localizedDescription)")
                debugLogger.log("HealthKit authorization FAILED: \(error.localizedDescription)", category: .error)
            }

            // Schedule daily summary notifications with ChatGPT-generated content (8 AM and 9 PM)
            await DailySummaryService.shared.scheduleDailySummaries()
            logger.info("✅ Daily summary notifications scheduled")
            debugLogger.log("Daily summary notifications scheduled", category: .app)

            // Process all recent workouts and weight entries on app launch
            logger.info("📥 Processing all recent workouts...")
            debugLogger.log("Processing all recent workouts on app launch...", category: .app)
            await BackgroundTaskService.shared.processAllRecentWorkouts()

            logger.info("📥 Processing all recent weight entries...")
            debugLogger.log("Processing all recent weight entries on app launch...", category: .app)
            await BackgroundTaskService.shared.processAllRecentWeightEntries()

            // Start observing (this will run indefinitely via AsyncStream)
            debugLogger.log("Starting HealthKit observer (will run indefinitely)...", category: .observer)
            await healthObserver?.startObserving()
        }
    }
}
