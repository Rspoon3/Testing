import Foundation

/// Factory for creating AI message services based on provider selection.
final class AIServiceFactory: Sendable {
    static let shared = AIServiceFactory()

    private let chatGPTService = ChatGPTService()

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Helpers

    /// Returns the appropriate AI service for the given provider.
    /// - Parameter provider: The AI provider to use.
    /// - Returns: An AI message service instance.
    func service(for provider: AIProvider) -> AIMessageService {
        switch provider {
        case .chatGPT:
            return chatGPTService
        case .foundationModel:
            if #available(iOS 26, *) {
                return FoundationModelService()
            }
            return chatGPTService
        }
    }

    /// Returns the service based on user preferences.
    /// - Returns: The currently selected AI message service.
    func currentService() -> AIMessageService {
        let provider = UserPreferences.shared.selectedAIProvider
        return service(for: provider)
    }
}
