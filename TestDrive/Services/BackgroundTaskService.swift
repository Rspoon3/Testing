import HealthKit
import UIKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "BackgroundTaskService")

/// Manages health data processing.
final class BackgroundTaskService {
    static let shared = BackgroundTaskService()

    private let healthKitService = HealthKitService()
    private let chatGPTService = ChatGPTService()
    private let notificationService = NotificationService.shared
    private let workoutMessageStore = WorkoutMessageStore.shared
    private let weightMessageStore = WeightMessageStore.shared
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

    /// Processes a new workout detected via observer query.
    /// - Parameters:
    ///   - workout: The detected workout.
    ///   - sendNotification: Whether to send a notification for this workout.
    func processWorkout(_ workout: HKWorkout, sendNotification: Bool = true) async {
        let workoutID = workout.uuid.uuidString
        logger.info("🏃 Processing workout: \(workoutID) - sendNotification: \(sendNotification)")
        logger.info("📱 App state: \(UIApplication.shared.applicationState.rawValue)")

        guard workoutMessageStore.message(forWorkoutID: workoutID) == nil else {
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
            workoutMessageStore.save(workoutMessage)
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

    /// Processes all recent weight entries that haven't been processed yet.
    /// - Parameter sendNotifications: Whether to send notifications for processed weight entries.
    func processAllRecentWeightEntries(sendNotifications: Bool = false) async {
        logger.info("📥 Fetching all recent weight entries...")

        let weightStats = await healthKitService.fetchWeightStats()
        logger.info("📊 Found \(weightStats.entries.count) total weight entries")

        for entry in weightStats.entries {
            await processWeightEntry(entry, sendNotification: sendNotifications)
        }

        logger.info("✅ Finished processing all weight entries")
    }

    /// Processes a new weight entry detected via observer query.
    /// - Parameters:
    ///   - weightEntry: The detected weight entry.
    ///   - sendNotification: Whether to send a notification for this weight entry.
    func processWeightEntry(_ weightEntry: WeightEntry, sendNotification: Bool = true) async {
        let entryID = weightEntry.id
        logger.info("⚖️ Processing weight entry: \(entryID) - sendNotification: \(sendNotification)")
        logger.info("📱 App state: \(UIApplication.shared.applicationState.rawValue)")

        guard weightMessageStore.message(forWeightEntryID: entryID) == nil else {
            logger.info("⏭️ Weight entry already has a message, skipping")
            return
        }

        let attitude = userPreferences.randomSelectedAttitude
        logger.info("🎭 Using attitude: \(attitude.rawValue)")

        do {
            // Fetch weight stats for context
            logger.info("📊 Fetching weight stats...")
            let weightStats = await healthKitService.fetchWeightStats()
            logger.info("📊 Weight stats: \(weightStats.entries.count) entries")

            // Fetch workout stats for fitness context
            logger.info("🏋️ Fetching workout stats...")
            let workoutStats = try await healthKitService.fetchWorkoutStats()
            logger.info("🏋️ Workout stats: \(workoutStats.monthly.totalWorkouts) workouts this month")

            // Fetch user profile
            logger.info("👤 Fetching user profile...")
            let userProfile = await healthKitService.fetchUserProfile()
            logger.info("👤 Profile: \(userProfile.formatForPrompt())")

            // Fetch workout streak
            logger.info("🔥 Fetching streak...")
            let streak = await healthKitService.fetchWorkoutStreak()
            logger.info("🔥 Streak: \(streak) days")

            logger.info("🤖 Calling ChatGPT for weight message...")
            let message = try await chatGPTService.generateWeightMessage(
                for: weightEntry,
                weightStats: weightStats,
                workoutStats: workoutStats,
                userProfile: userProfile,
                streak: streak,
                attitude: attitude
            )
            logger.info("✅ Got message: \(message)")

            // Save the message
            let weightMessage = WeightMessage(
                weightEntryID: entryID,
                weightInPounds: weightEntry.weightInPounds,
                message: message,
                attitude: attitude.rawValue,
                entryDate: weightEntry.date
            )
            weightMessageStore.save(weightMessage)
            logger.info("💾 Weight message saved")

            if sendNotification {
                logger.info("🔔 Scheduling notification...")
                await notificationService.scheduleWeightNotification(
                    title: "Weight Logged!",
                    body: message,
                    weightEntryID: entryID
                )
                logger.info("✅ Notification scheduled")
            } else {
                logger.info("⏭️ Skipping notification (bulk processing)")
            }
        } catch {
            logger.error("❌ ChatGPT API failed: \(error.localizedDescription)")
        }
    }

}
