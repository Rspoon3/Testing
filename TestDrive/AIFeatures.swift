import Foundation
import FoundationModels

enum SummaryLength: String, CaseIterable {
    case brief = "brief"
    case medium = "medium"
    case detailed = "detailed"

    var description: String {
        switch self {
        case .brief:
            return "a brief, 1-2 sentence summary"
        case .medium:
            return "a concise paragraph summary"
        case .detailed:
            return "a detailed summary with key points"
        }
    }
}

enum TitleStyle: String, CaseIterable {
    case descriptive = "descriptive"
    case creative = "creative"
    case topical = "topical"

    var description: String {
        switch self {
        case .descriptive:
            return "descriptive and informative"
        case .creative:
            return "creative and engaging"
        case .topical:
            return "topic-focused and professional"
        }
    }
}

enum TranscriptionCategory: String, CaseIterable, Codable {
    case meeting = "Meeting"
    case interview = "Interview"
    case lecture = "Lecture"
    case conversation = "Conversation"
    case memo = "Personal Memo"
    case other = "Other"

    var icon: String {
        switch self {
        case .meeting:
            return "person.3.fill"
        case .interview:
            return "questionmark.circle.fill"
        case .lecture:
            return "graduationcap.fill"
        case .conversation:
            return "bubble.left.and.bubble.right.fill"
        case .memo:
            return "note.text"
        case .other:
            return "doc.text.fill"
        }
    }
}

class AIManager {
    static let shared = AIManager()
    private init() {}

    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    private func createSession() async throws -> LanguageModelSession {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIError.unavailable
        }

        return LanguageModelSession(model: SystemLanguageModel.default)
    }

    func generateSummary(for text: String, length: SummaryLength = .medium) async throws -> String? {
        let session = try await createSession()

        let prompt = """
        Please provide \(length.description) of the following transcription. Focus on the main points and key information. Return only the summary with no additional text or formatting.

        Transcription: \(text)
        """

        let response = try await session.respond(to: prompt)
        let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        return summary.isEmpty ? nil : summary
    }

    func generateTitle(for text: String, style: TitleStyle = .descriptive) async throws -> String? {
        let session = try await createSession()

        let prompt = """
        Generate a \(style.description) title for this transcription. The title should be concise and capture the main topic. Return only the title with no additional text, quotes, or formatting.

        Transcription: \(text)
        """

        let response = try await session.respond(to: prompt)
        let title = response.content.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        return title.isEmpty ? nil : title
    }

    func classifyContent(for text: String) async throws -> TranscriptionCategory? {
        let session = try await createSession()

        let categories = TranscriptionCategory.allCases.map { $0.rawValue }.joined(separator: ", ")

        let prompt = """
        Classify this transcription into one of these categories: \(categories).

        Consider the content, tone, and structure to determine the most appropriate category. Return only the category name with no additional text.

        Transcription: \(text)
        """

        let response = try await session.respond(to: prompt)
        let categoryText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        return TranscriptionCategory.allCases.first { $0.rawValue.lowercased() == categoryText.lowercased() } ?? .other
    }

    func extractKeyPoints(for text: String) async throws -> [String]? {
        let session = try await createSession()

        let prompt = """
        Extract the key points from this transcription. Return each key point as a separate line starting with "• ". Focus on actionable items, important decisions, and main topics discussed.

        Transcription: \(text)
        """

        let response = try await session.respond(to: prompt)
        let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        if content.isEmpty {
            return nil
        }

        let keyPoints = content.components(separatedBy: .newlines)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("•") {
                    return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return trimmed.isEmpty ? nil : trimmed
            }

        return keyPoints.isEmpty ? nil : keyPoints
    }
}

enum AIError: Error {
    case unavailable
    case emptyResponse
    case processingFailed

    var localizedDescription: String {
        switch self {
        case .unavailable:
            return "Apple Intelligence is not available on this device"
        case .emptyResponse:
            return "AI processing returned empty response"
        case .processingFailed:
            return "AI processing failed"
        }
    }
}