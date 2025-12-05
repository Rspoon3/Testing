import Foundation
import HealthKit

/// Errors that can occur during AI message generation.
enum AIServiceError: Error, LocalizedError {
    case invalidResponse(statusCode: Int, body: String)
    case noContent
    case networkError(Error)
    case decodingError(Error)
    case modelNotAvailable
    case generationFailed(String)

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
        case .modelNotAvailable:
            return "AI model is not available on this device"
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        }
    }
}

/// Protocol for AI message generation services.
protocol AIMessageService: Sendable {
    /// Generates a personalized message for a workout.
    /// - Parameters:
    ///   - workout: The completed workout.
    ///   - stats: The user's workout statistics for today, weekly, and monthly.
    ///   - userProfile: The user's profile data from HealthKit.
    ///   - lastWorkoutDate: The date of the previous workout, if any.
    ///   - heartRate: Heart rate data for the workout.
    ///   - streak: Current consecutive workout day streak.
    ///   - attitudes: The user's selected attitude tones.
    /// - Returns: A personalized message string.
    /// - Throws: AIServiceError if generation fails.
    func generateMessage(
        for workout: HKWorkout,
        stats: WorkoutStats,
        userProfile: UserProfile,
        lastWorkoutDate: Date?,
        heartRate: WorkoutHeartRate,
        streak: Int,
        attitudes: Set<Attitude>
    ) async throws -> String

    /// Generates a personalized message for a weight entry.
    /// - Parameters:
    ///   - weightEntry: The new weight entry.
    ///   - weightStats: Weight statistics for the last 30 days.
    ///   - workoutStats: The user's workout statistics for context.
    ///   - userProfile: The user's profile data from HealthKit.
    ///   - streak: Current consecutive workout day streak.
    ///   - attitudes: The user's selected attitude tones.
    /// - Returns: A personalized message string.
    /// - Throws: AIServiceError if generation fails.
    func generateWeightMessage(
        for weightEntry: WeightEntry,
        weightStats: WeightStats,
        workoutStats: WorkoutStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) async throws -> String

    /// Generates a morning summary message.
    /// - Parameters:
    ///   - workoutStats: The user's workout statistics.
    ///   - weightStats: Weight statistics for the last 30 days.
    ///   - userProfile: The user's profile data from HealthKit.
    ///   - streak: Current consecutive workout day streak.
    ///   - attitudes: The user's selected attitude tones.
    /// - Returns: A personalized morning summary message.
    /// - Throws: AIServiceError if generation fails.
    func generateMorningSummary(
        workoutStats: WorkoutStats,
        weightStats: WeightStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) async throws -> String

    /// Generates an evening summary message.
    /// - Parameters:
    ///   - workoutStats: The user's workout statistics.
    ///   - weightStats: Weight statistics for the last 30 days.
    ///   - userProfile: The user's profile data from HealthKit.
    ///   - streak: Current consecutive workout day streak.
    ///   - attitudes: The user's selected attitude tones.
    /// - Returns: A personalized evening summary message.
    /// - Throws: AIServiceError if generation fails.
    func generateEveningSummary(
        workoutStats: WorkoutStats,
        weightStats: WeightStats,
        userProfile: UserProfile,
        streak: Int,
        attitudes: Set<Attitude>
    ) async throws -> String
}
