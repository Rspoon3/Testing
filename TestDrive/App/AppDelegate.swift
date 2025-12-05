import UIKit
import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "AppDelegate")

/// App delegate for handling background tasks and HealthKit observer.
class AppDelegate: NSObject, UIApplicationDelegate {
    private var workoutObserver: WorkoutObserver?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("🚀 App launched")

        // Register background tasks
        BackgroundTaskService.shared.registerBackgroundTask()
        logger.info("✅ Background task registered")

        // Setup HealthKit background delivery
        setupHealthKitObserver()

        return true
    }

    // MARK: - Private Helpers

    private func setupHealthKitObserver() {
        logger.info("🏥 Setting up HealthKit observer...")

        let healthStore = HKHealthStore()
        workoutObserver = WorkoutObserver(healthStore: healthStore)

        Task {
            do {
                try await workoutObserver?.enableBackgroundDelivery()
                logger.info("✅ Background delivery enabled")

                workoutObserver?.startObserving()
                logger.info("✅ Workout observer started")

                workoutObserver?.onWorkoutDetected = { workout in
                    logger.info("🏋️ Workout detected: \(workout.workoutActivityType.rawValue)")
                    Task {
                        await BackgroundTaskService.shared.processWorkout(workout)
                    }
                }
            } catch {
                logger.error("❌ Failed to setup HealthKit observer: \(error.localizedDescription)")
            }
        }
    }
}
