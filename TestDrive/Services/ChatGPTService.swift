import Foundation
import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "ChatGPTService")

/// Errors that can occur during ChatGPT API calls.
enum ChatGPTError: Error, LocalizedError {
    case invalidResponse(statusCode: Int, body: String)
    case noContent
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let statusCode, let body):
            return "Invalid response (status \(statusCode)): \(body)"
        case .noContent:
            return "No content in response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

/// Request body for OpenAI Chat Completions API.
private struct ChatGPTRequest: Encodable {
    let model: String
    let messages: [Message]
    let maxTokens: Int

    struct Message: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

/// Response from OpenAI Chat Completions API.
private struct ChatGPTResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

/// Service for generating personalized messages via OpenAI API.
final class ChatGPTService {
    // MVP: Hardcoded API key (move to secure storage for production)
    private let apiKey = ""
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    // MARK: - Public Helpers

    /// Generates a personalized message for a workout.
    /// - Parameters:
    ///   - workout: The completed workout.
    ///   - stats: The user's workout statistics for today, weekly, and monthly.
    ///   - userProfile: The user's profile data from HealthKit.
    ///   - lastWorkoutDate: The date of the previous workout, if any.
    ///   - heartRate: Heart rate data for the workout.
    ///   - streak: Current consecutive workout day streak.
    ///   - attitude: The user's selected attitude tone.
    /// - Returns: A personalized message string.
    /// - Throws: ChatGPTError if the API call fails.
    func generateMessage(
        for workout: HKWorkout,
        stats: WorkoutStats,
        userProfile: UserProfile,
        lastWorkoutDate: Date?,
        heartRate: WorkoutHeartRate,
        streak: Int,
        attitude: Attitude
    ) async throws -> String {
        try await fetchFromAPI(
            workout: workout,
            stats: stats,
            userProfile: userProfile,
            lastWorkoutDate: lastWorkoutDate,
            heartRate: heartRate,
            streak: streak,
            attitude: attitude
        )
    }

    // MARK: - Private Helpers

    private func fetchFromAPI(
        workout: HKWorkout,
        stats: WorkoutStats,
        userProfile: UserProfile,
        lastWorkoutDate: Date?,
        heartRate: WorkoutHeartRate,
        streak: Int,
        attitude: Attitude
    ) async throws -> String {
        let systemPrompt = """
        You are a health buddy. Your job is to comment on a person's recent fitness activity.

        Based on the attitude parameter, vary your response:
        - neutral: Matter-of-fact, informative
        - sarcastic: Playfully teasing, witty
        - funny: Humorous, lighthearted jokes
        - cute: Sweet, encouraging with enthusiasm
        - encouraging: Motivational, supportive
        - coaching: Professional trainer vibe, constructive feedback
        - aggressive: Intense drill sergeant energy, push them harder, no excuses
        - mean: Brutally honest, roast them, tough love with bite

        You will receive:
        - Current time (use for time-appropriate greetings like "early bird!" or "late night workout!")
        - User profile (age, sex, height, weight - use to personalize if relevant)
        - Last workout date (when they last exercised before this workout)
        - Current workout details (type, duration, start/end times, calories, distance)
        - Heart rate data (average, max, min BPM during workout)
        - Current workout streak (consecutive days with workouts)
        - Today's, weekly, and monthly statistics (with min/max/avg)

        Use this data to provide context:
        - Consider the time of day (early morning, late night, lunch break, etc.)
        - Reference how long it's been since their last workout (e.g., "back at it after 3 days!" or "two days in a row!")
        - If it's been more than a few days, welcome them back; if it's consecutive days, celebrate their streak
        - Comment on their heart rate if notable (high intensity, staying in zone, etc.)
        - If they have a streak going, acknowledge it appropriately for the attitude
        - If they've done multiple workouts today, acknowledge their dedication or hustle
        - If this workout's metrics are near their personal best (max), celebrate it
        - If this workout is significantly below their average or near their minimum, mention it (adjust tone based on attitude)
        - Reference their monthly totals to show progress awareness

        Keep responses under 2-5 sentences. Be conversational and natural. Don't list statistics back - weave insights naturally into your message.
        """

        let workoutDetails = formatWorkoutDetails(workout)
        let comparison = formatComparison(workout: workout, stats: stats)
        let statsContext = stats.formatForPrompt()
        let profileContext = userProfile.formatForPrompt()
        let currentTime = formatCurrentTime()
        let lastWorkoutContext = formatLastWorkoutDate(lastWorkoutDate)
        let heartRateContext = heartRate.formatForPrompt()
        let streakContext = formatStreak(streak)

        logger.info("📋 Workout details: \(workoutDetails)")
        logger.info("📊 Stats context: \(statsContext)")
        logger.info("👤 Profile: \(profileContext)")
        logger.info("🕐 Time: \(currentTime)")
        logger.info("📅 Last workout: \(lastWorkoutContext)")
        logger.info("💓 Heart rate: \(heartRateContext)")
        logger.info("🔥 Streak: \(streakContext)")

        let userPrompt = """
        Attitude: \(attitude.rawValue)

        \(currentTime)

        \(profileContext)

        \(lastWorkoutContext)

        \(streakContext)

        Current Workout:
        \(workoutDetails)

        \(heartRateContext)

        \(statsContext)

        \(comparison)

        Generate a personalized message about this workout.
        """

        let request = ChatGPTRequest(
            model: "gpt-4o-mini",
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            maxTokens: 200
        )

        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        logger.info("🌐 Sending request to OpenAI...")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ No HTTP response")
            throw ChatGPTError.invalidResponse(statusCode: 0, body: "No HTTP response")
        }

        logger.info("📥 Response status: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("❌ API error: \(body)")
            throw ChatGPTError.invalidResponse(statusCode: httpResponse.statusCode, body: body)
        }

        do {
            let chatResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)

            guard let message = chatResponse.choices.first?.message.content else {
                logger.error("❌ No content in response")
                throw ChatGPTError.noContent
            }

            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("✅ Generated message: \(trimmedMessage)")
            return trimmedMessage
        } catch let error as DecodingError {
            let body = String(data: data, encoding: .utf8) ?? "Unknown"
            logger.error("❌ Decoding error: \(error.localizedDescription), body: \(body)")
            throw ChatGPTError.decodingError(error)
        }
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

    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return "Current time: \(formatter.string(from: Date()))"
    }

    private func formatLastWorkoutDate(_ lastWorkoutDate: Date?) -> String {
        guard let lastDate = lastWorkoutDate else {
            return "Last workout: This is their first recorded workout!"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return "Last workout: \(formatter.string(from: lastDate))"
    }

    private func formatComparison(workout: HKWorkout, stats: WorkoutStats) -> String {
        guard let typeStats = stats.monthlyStats(for: workout.workoutActivityType) else {
            return "This is their first \(workout.workoutActivityType.displayName) workout in the last 30 days!"
        }

        let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        let distance = workout.totalDistance?.doubleValue(for: .mile()) ?? 0
        let duration = workout.duration / 60

        var comparisons: [String] = []

        // Compare calories
        if typeStats.averageCalories > 0 && calories > 0 {
            let calorieDiff = ((calories - typeStats.averageCalories) / typeStats.averageCalories) * 100
            if calorieDiff < -20 {
                comparisons.append("Calories are \(Int(abs(calorieDiff)))% below your average")
            } else if calorieDiff > 20 {
                comparisons.append("Calories are \(Int(calorieDiff))% above your average")
            }
        }

        // Compare distance
        if typeStats.averageDistance > 0 && distance > 0 {
            let distanceDiff = ((distance - typeStats.averageDistance) / typeStats.averageDistance) * 100
            if distanceDiff < -20 {
                comparisons.append("Distance is \(Int(abs(distanceDiff)))% below your average")
            } else if distanceDiff > 20 {
                comparisons.append("Distance is \(Int(distanceDiff))% above your average")
            }
        }

        // Compare duration
        if typeStats.averageDuration > 0 {
            let durationDiff = ((duration - typeStats.averageDuration) / typeStats.averageDuration) * 100
            if durationDiff < -20 {
                comparisons.append("Duration is \(Int(abs(durationDiff)))% below your average")
            } else if durationDiff > 20 {
                comparisons.append("Duration is \(Int(durationDiff))% above your average")
            }
        }

        if comparisons.isEmpty {
            return "This workout is right around your typical \(workout.workoutActivityType.displayName) performance."
        }

        return "Comparison to your averages: " + comparisons.joined(separator: ". ") + "."
    }
}
