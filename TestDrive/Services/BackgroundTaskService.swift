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
    private let messageStore = WorkoutMessageStore.shared
    private let userPreferences = UserPreferences.shared

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Helpers

    /// Processes all recent workouts that haven't been processed yet.
    /// - Parameter sendNotifications: Whether to send notifications for processed workouts.
    func processAllRecentWorkouts(sendNotifications: Bool = false) async {
        logger.info("📥 Fetching all recent workouts...")

        do {
            let workouts = try await healthKitService.fetchRecentWorkouts()
            logger.info("📊 Found \(workouts.count) total workouts")

            for workout in workouts {
                await processWorkout(workout, sendNotification: sendNotifications)
            }

            logger.info("✅ Finished processing all workouts")
        } catch {
            logger.error("❌ Failed to fetch workouts: \(error.localizedDescription)")
        }
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
    /// - Parameters:
    ///   - workout: The detected workout.
    ///   - sendNotification: Whether to send a notification for this workout.
    func processWorkout(_ workout: HKWorkout, sendNotification: Bool = true) async {
        let workoutID = workout.uuid.uuidString
        logger.info("🏃 Processing workout: \(workoutID)")

        guard messageStore.message(forWorkoutID: workoutID) == nil else {
            logger.info("⏭️ Workout already has a message, skipping")
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

            // Fetch user profile
            logger.info("👤 Fetching user profile...")
            let userProfile = await healthKitService.fetchUserProfile()
            logger.info("👤 Profile: \(userProfile.formatForPrompt())")

            // Fetch previous workout date
            logger.info("📅 Fetching previous workout...")
            let previousWorkout = try? await healthKitService.fetchPreviousWorkout(before: workout)
            let lastWorkoutDate = previousWorkout?.endDate
            logger.info("📅 Previous workout: \(lastWorkoutDate?.description ?? "none")")

            // Fetch heart rate data
            logger.info("💓 Fetching heart rate...")
            let heartRate = await healthKitService.fetchHeartRate(for: workout)
            logger.info("💓 Heart rate: \(heartRate.formatForPrompt())")

            // Fetch workout streak
            logger.info("🔥 Fetching streak...")
            let streak = await healthKitService.fetchWorkoutStreak()
            logger.info("🔥 Streak: \(streak) days")

            logger.info("🤖 Calling ChatGPT...")
            let message = try await chatGPTService.generateMessage(
                for: workout,
                stats: stats,
                userProfile: userProfile,
                lastWorkoutDate: lastWorkoutDate,
                heartRate: heartRate,
                streak: streak,
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

            if sendNotification {
                logger.info("🔔 Scheduling notification...")
                await notificationService.scheduleNotification(
                    title: "Workout Complete!",
                    body: message,
                    workoutID: workoutID
                )
                logger.info("✅ Notification scheduled")
            } else {
                logger.info("⏭️ Skipping notification (bulk processing)")
            }
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
