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
    private let notificationService = NotificationService.shared
    private let processedWorkoutsStore = ProcessedWorkoutsStore()
    private let messageStore = WorkoutMessageStore.shared
    private let userPreferences = UserPreferences.shared

    // MARK: - Initializer

    private init() {}

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
            // Fetch workout stats for context
            logger.info("📊 Fetching workout stats...")
            let stats = try await healthKitService.fetchWorkoutStats()
            logger.info("📊 Stats: \(stats.today.totalWorkouts) today, \(stats.weekly.totalWorkouts) this week, \(stats.monthly.totalWorkouts) this month")

            logger.info("🤖 Calling ChatGPT...")
            let message = try await chatGPTService.generateMessage(
                for: workout,
                stats: stats,
                attitude: attitude
            )
            logger.info("✅ Got message: \(message)")

            // Save the message
            let workoutMessage = WorkoutMessage(
                workoutID: workoutID,
                activityType: String(workout.workoutActivityType.rawValue),
                activityName: workout.workoutActivityType.displayName,
                duration: workout.duration,
                calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                distance: workout.totalDistance?.doubleValue(for: .mile()) ?? 0,
                message: message,
                attitude: attitude.rawValue,
                workoutDate: workout.endDate
            )
            messageStore.save(workoutMessage)
            logger.info("💾 Message saved")

            logger.info("🔔 Scheduling notification...")
            await notificationService.scheduleNotification(
                title: "Workout Complete!",
                body: message,
                workoutID: workoutID
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
