import BackgroundTasks
import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "BackgroundTaskService")

/// Manages background task scheduling and execution.
final class BackgroundTaskService {
    static let shared = BackgroundTaskService()
    static let taskIdentifier = "com.rspoon3.TestDrive.workoutRefresh"

    private let healthKitService = HealthKitService()
    private let chatGPTService = ChatGPTService()
    private let notificationService = NotificationService()
    private let processedWorkoutsStore = ProcessedWorkoutsStore()
    private let userPreferences = UserPreferences.shared

    /// Timestamp when the observer started - only process workouts after this time
    private var observerStartTime: Date?

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Helpers

    /// Marks the observer as started. Workouts before this time will be ignored.
    func markObserverStarted() {
        observerStartTime = Date()
        logger.info("⏱️ Observer start time set: \(self.observerStartTime!)")
    }

    /// Registers the background task handler. Call in AppDelegate.
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            logger.info("📋 Background task handler called")
            self?.handleBackgroundTask(task as! BGProcessingTask)
        }
    }

    /// Schedules a background processing task.
    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("✅ Background task scheduled")
        } catch {
            logger.error("❌ Failed to schedule background task: \(error.localizedDescription)")
        }
    }

    /// Processes a new workout detected via observer query.
    /// - Parameter workout: The detected workout.
    func processWorkout(_ workout: HKWorkout) async {
        let workoutID = workout.uuid.uuidString
        logger.info("🏃 Processing workout: \(workoutID)")

        // Only process workouts that ended after we started observing
        if let startTime = observerStartTime {
            guard workout.endDate > startTime else {
                logger.info("⏭️ Workout ended before observer started, skipping (ended: \(workout.endDate), observer started: \(startTime))")
                return
            }
        }

        guard !processedWorkoutsStore.isProcessed(workoutID) else {
            logger.info("⏭️ Workout already processed, skipping")
            return
        }

        // Check if it's a tracked workout type
        guard HealthKitService.trackedWorkoutTypes.contains(workout.workoutActivityType) else {
            logger.info("⏭️ Workout type not tracked: \(workout.workoutActivityType.rawValue)")
            return
        }

        let attitude = userPreferences.randomSelectedAttitude
        logger.info("🎭 Using attitude: \(attitude.rawValue)")

        do {
            logger.info("🤖 Calling ChatGPT...")
            let message = try await chatGPTService.generateMessage(for: workout, attitude: attitude)
            logger.info("✅ Got message: \(message)")

            logger.info("🔔 Scheduling notification...")
            await notificationService.scheduleNotification(
                title: "Workout Complete!",
                body: message
            )
            logger.info("✅ Notification scheduled")

            processedWorkoutsStore.markAsProcessed(workoutID)
            logger.info("✅ Workout marked as processed")
        } catch {
            logger.error("❌ ChatGPT API failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func handleBackgroundTask(_ task: BGProcessingTask) {
        logger.info("🔄 Handling background task...")
        scheduleBackgroundTask()

        task.expirationHandler = {
            logger.warning("⚠️ Background task expired")
            task.setTaskCompleted(success: false)
        }

        Task {
            do {
                try await processNewWorkouts()
                logger.info("✅ Background task completed successfully")
                task.setTaskCompleted(success: true)
            } catch {
                logger.error("❌ Background task failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
    }

    private func processNewWorkouts() async throws {
        logger.info("📥 Fetching recent workouts...")
        let workouts = try await healthKitService.fetchRecentWorkouts()
        logger.info("📊 Found \(workouts.count) workouts")

        for workout in workouts {
            await processWorkout(workout)
        }
    }
}
