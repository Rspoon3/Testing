import Foundation
import HealthKit
import os.log

#if canImport(FoundationModels)
import FoundationModels
#endif

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "FoundationModelService")

/// Service for generating personalized messages via Apple's on-device Foundation Model (iOS 26+).
@available(iOS 26, *)
final class FoundationModelService: AIMessageService, @unchecked Sendable {

    // MARK: - Public Helpers

    func generateMessage(
        for workout: HKWorkout,
        stats: WorkoutStats,
        userProfile: UserProfile,
        lastWorkoutDate: Date?,
        heartRate: WorkoutHeartRate,
        streak: Int,
        attitudes: Set<Attitude>
    ) async throws -> String {
        let prompt = buildWorkoutPrompt(
            workout: workout,
            stats: stats,
            userProfile: userProfile,
            lastWorkoutDate: lastWorkoutDate,
            heartRate: heartRate,
            streak: streak,
            attitudes: attitudes
        )

        return try await generateWithFoundationModel(prompt: prompt)
    }

    func generateWeightMessage(
        for weightEntry: WeightEntry,
        weightStats: WeightStats,
        workoutStats: WorkoutStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) async throws -> String {
        let prompt = buildWeightPrompt(
            weightEntry: weightEntry,
            weightStats: weightStats,
            workoutStats: workoutStats,
            userProfile: userProfile,
            streak: streak,
            attitudes: attitudes
        )

        return try await generateWithFoundationModel(prompt: prompt)
    }

    func generateMorningSummary(
        workoutStats: WorkoutStats,
        weightStats: WeightStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) async throws -> String {
        let prompt = buildMorningSummaryPrompt(
            workoutStats: workoutStats,
            weightStats: weightStats,
            userProfile: userProfile,
            streak: streak,
            attitudes: attitudes
        )

        return try await generateWithFoundationModel(prompt: prompt)
    }

    func generateEveningSummary(
        workoutStats: WorkoutStats,
        weightStats: WeightStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) async throws -> String {
        let prompt = buildEveningSummaryPrompt(
            workoutStats: workoutStats,
            weightStats: weightStats,
            userProfile: userProfile,
            streak: streak,
            attitudes: attitudes
        )

        return try await generateWithFoundationModel(prompt: prompt)
    }

    // MARK: - Private Helpers

    private func generateWithFoundationModel(prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        logger.info("🤖 Generating with Foundation Model...")

        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)

        let message = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        logger.info("✅ Foundation Model response: \(message)")
        return message
        #else
        logger.error("❌ FoundationModels framework not available")
        throw AIServiceError.modelNotAvailable
        #endif
    }

    private func buildWorkoutPrompt(
        workout: HKWorkout,
        stats: WorkoutStats,
        userProfile: UserProfile,
        lastWorkoutDate: Date?,
        heartRate: WorkoutHeartRate,
        streak: Int,
        attitudes: Set<Attitude>
    ) -> String {
        let attitudesString = attitudes.map(\.rawValue).sorted().joined(separator: ", ")
        let workoutDetails = formatWorkoutDetails(workout)
        let workoutTime = formatTime(workout.startDate, label: "Workout time")
        let lastWorkoutContext = formatLastWorkoutDate(lastWorkoutDate)
        let streakContext = formatStreak(streak)
        let profileContext = userProfile.formatForPrompt()
        let statsContext = stats.formatForPrompt()
        let heartRateContext = heartRate.formatForPrompt()

        return """
        You are a health buddy commenting on a person's recent fitness activity.

        Blend these attitudes naturally in your response: \(attitudesString)
        - neutral: Matter-of-fact, informative
        - sarcastic: Playfully teasing, witty
        - funny: Humorous, lighthearted jokes
        - cute: Sweet, encouraging with enthusiasm
        - encouraging: Motivational, supportive
        - coaching: Professional trainer vibe, constructive feedback
        - aggressive: Intense drill sergeant energy, push them harder
        - mean: Brutally honest, roast them, tough love

        \(workoutTime)
        \(profileContext)
        \(lastWorkoutContext)
        \(streakContext)

        Current Workout:
        \(workoutDetails)

        \(heartRateContext)
        \(statsContext)

        Generate a personalized 2-5 sentence message about this workout. Be conversational and natural.
        """
    }

    private func buildWeightPrompt(
        weightEntry: WeightEntry,
        weightStats: WeightStats,
        workoutStats: WorkoutStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) -> String {
        let attitudesString = attitudes.map(\.rawValue).sorted().joined(separator: ", ")
        let weightTime = formatTime(weightEntry.date, label: "Weight recorded")
        let profileContext = userProfile.formatForPrompt()
        let weightContext = weightStats.formatForPrompt()
        let workoutContext = workoutStats.formatForPrompt()
        let streakContext = formatStreak(streak)

        return """
        You are a health buddy commenting on a person's new weight entry.

        Blend these attitudes naturally in your response: \(attitudesString)

        \(weightTime)
        \(profileContext)
        \(streakContext)

        New Weight Entry:
        Weight: \(weightEntry.formattedWeight)

        Weight History (Last 30 Days):
        \(weightContext)

        Fitness Context:
        \(workoutContext)

        Generate a personalized 2-5 sentence message about this weight entry. Be conversational and natural.
        """
    }

    private func buildMorningSummaryPrompt(
        workoutStats: WorkoutStats,
        weightStats: WeightStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) -> String {
        let attitudesString = attitudes.map(\.rawValue).sorted().joined(separator: ", ")
        let currentTime = formatTime(Date(), label: "Current time")
        let profileContext = userProfile.formatForPrompt()
        let workoutContext = workoutStats.formatForPrompt()
        let weightContext = weightStats.formatForPrompt()
        let streakContext = formatStreak(streak)

        return """
        You are a health buddy delivering a morning motivation message.

        Blend these attitudes naturally in your response: \(attitudesString)

        \(currentTime)
        \(profileContext)
        \(streakContext)

        Overall Stats:
        \(workoutContext)

        Weight Trends:
        \(weightContext)

        Generate a morning motivation message in 2-3 sentences. Greet them, recap yesterday briefly, and motivate for today.
        """
    }

    private func buildEveningSummaryPrompt(
        workoutStats: WorkoutStats,
        weightStats: WeightStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) -> String {
        let attitudesString = attitudes.map(\.rawValue).sorted().joined(separator: ", ")
        let currentTime = formatTime(Date(), label: "Current time")
        let profileContext = userProfile.formatForPrompt()
        let workoutContext = workoutStats.formatForPrompt()
        let weightContext = weightStats.formatForPrompt()
        let streakContext = formatStreak(streak)

        return """
        You are a health buddy delivering an end-of-day summary message.

        Blend these attitudes naturally in your response: \(attitudesString)

        \(currentTime)
        \(profileContext)
        \(streakContext)

        Overall Stats:
        \(workoutContext)

        Weight Trends:
        \(weightContext)

        Generate an evening summary message in 2-3 sentences. Wrap up their day, highlight accomplishments, and set them up for tomorrow.
        """
    }

    private func formatWorkoutDetails(_ workout: HKWorkout) -> String {
        let activityName = workout.workoutActivityType.displayName
        let duration = Int(workout.duration / 60)
        let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        let distance = workout.totalDistance?.doubleValue(for: .mile()) ?? 0

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTime = timeFormatter.string(from: workout.startDate)
        let endTime = timeFormatter.string(from: workout.endDate)

        var details = "\(activityName) for \(duration) minutes (started \(startTime), ended \(endTime))"

        if calories > 0 {
            details += ", burned \(Int(calories)) calories"
        }

        if distance > 0 {
            details += ", covered \(String(format: "%.1f", distance)) miles"
        }

        return details
    }

    private func formatStreak(_ streak: Int) -> String {
        if streak == 0 {
            return "Workout streak: Starting fresh (no consecutive days yet)"
        } else if streak == 1 {
            return "Workout streak: 1 day"
        } else {
            return "Workout streak: \(streak) consecutive days"
        }
    }

    private func formatTime(_ date: Date, label: String = "Time") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return "\(label): \(formatter.string(from: date))"
    }

    private func formatLastWorkoutDate(_ lastWorkoutDate: Date?) -> String {
        guard let lastDate = lastWorkoutDate else {
            return "Last workout: This is their first recorded workout!"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return "Last workout: \(formatter.string(from: lastDate))"
    }
}
