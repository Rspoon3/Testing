import UIKit
import HealthKit
import os.log
import RevenueCat
import MomentumCore
import MomentumHealth
import MomentumSummary
import MomentumPurchase
import MomentumReview
import MomentumPersistence
import MomentumOnboarding

private let logger = Logger(subsystem: "com.rspoon3.Momentum", category: "AppDelegate")
private let debugLogger = DebugLogger.shared

/// App delegate for handling HealthKit observer setup.
public class AppDelegate: NSObject, UIApplicationDelegate {
    private var healthObserver: HealthObserver?
    private var hasStartedHealthKitServices = false

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("🚀 App launched")
        debugLogger.log("APP LAUNCHED - didFinishLaunchingWithOptions", category: .app)

        configureRevenueCat()
        setupHealthKitObserver()
        recordAppLaunchForReview()

        // Listen for health permissions granted to start HealthKit services early
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHealthPermissionsGranted),
            name: OnboardingViewModel.healthPermissionsGrantedNotification,
            object: nil
        )

        return true
    }

    // MARK: - Private Helpers

    @objc private func handleHealthPermissionsGranted() {
        logger.info("📣 Health permissions granted notification received")
        debugLogger.log("Health permissions granted - starting HealthKit services", category: .app)
        startHealthKitServicesIfNeeded()
    }

    private func configureRevenueCat() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif

        Purchases.configure(withAPIKey: "appl_pskeaqsPEvHTxYbHbPlWgPZpPYP")
        logger.info("💰 RevenueCat configured")
        debugLogger.log("RevenueCat configured", category: .app)

        Task {
            try? await MomentumSubscriptionManager.shared.fetchOfferings()
            try? await MomentumSubscriptionManager.shared.refreshSubscription()
            logger.info("💰 RevenueCat offerings fetched and subscription refreshed")
            debugLogger.log("RevenueCat offerings fetched and subscription refreshed", category: .app)
        }
    }

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

        // Start services if onboarding already complete
        if UserPreferences.shared.hasCompletedOnboarding {
            startHealthKitServicesIfNeeded()
        } else {
            logger.info("⏭️ Waiting for health permissions before starting HealthKit services")
            debugLogger.log("Waiting for health permissions", category: .app)
        }
    }

    private func startHealthKitServicesIfNeeded() {
        guard !hasStartedHealthKitServices else {
            logger.info("⏭️ HealthKit services already started, skipping")
            return
        }
        hasStartedHealthKitServices = true
        Task {
            // Schedule daily summary notifications
            await DailySummaryService.shared.scheduleDailySummaries()
            logger.info("✅ Daily summary notifications scheduled")
            debugLogger.log("Daily summary notifications scheduled", category: .app)

            // Process all recent workouts and weight entries
            logger.info("📥 Processing all recent workouts...")
            debugLogger.log("Processing all recent workouts...", category: .app)
            await BackgroundTaskService.shared.processAllRecentWorkouts()

            logger.info("📥 Processing all recent weight entries...")
            debugLogger.log("Processing all recent weight entries...", category: .app)
            await BackgroundTaskService.shared.processAllRecentWeightEntries()

            // Start observing (this will run indefinitely via AsyncStream)
            debugLogger.log("Starting HealthKit observer (will run indefinitely)...", category: .observer)
            await healthObserver?.startObserving()
        }
    }

    private func recordAppLaunchForReview() {
        Task { @MainActor in
            ReviewService.shared.recordAppLaunch()
            logger.info("📝 Recorded app launch for review tracking")
        }
    }
}
