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
    ///   - attitude: The user's selected attitude tone.
    /// - Returns: A personalized message string.
    /// - Throws: ChatGPTError if the API call fails.
    func generateMessage(for workout: HKWorkout, attitude: Attitude) async throws -> String {
        try await fetchFromAPI(workout: workout, attitude: attitude)
    }

    // MARK: - Private Helpers

    private func fetchFromAPI(workout: HKWorkout, attitude: Attitude) async throws -> String {
        let systemPrompt = """
        You are a health buddy. Your job is to comment on a person's recent fitness activity. \
        Based on the attitude parameter, vary your response. Keep responses under 2 sentences. \
        Be conversational and natural.
        """

        let workoutDetails = formatWorkoutDetails(workout)
        logger.info("📋 Workout details: \(workoutDetails)")

        let userPrompt = """
        Attitude: \(attitude.rawValue)
        Workout: \(workoutDetails)

        Generate a short, personalized message about this workout completion.
        """

        let request = ChatGPTRequest(
            model: "gpt-4o-mini",
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            maxTokens: 100
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

        var details = "\(activityName) for \(duration) minutes"

        if calories > 0 {
            details += ", burned \(Int(calories)) calories"
        }

        if distance > 0 {
            details += ", covered \(String(format: "%.1f", distance)) miles"
        }

        return details
    }
}
