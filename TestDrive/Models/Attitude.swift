import SFSymbols

/// The available attitudes for AI-generated workout messages.
enum Attitude: String, CaseIterable, Identifiable {
    case neutral = "Neutral"
    case sarcastic = "Sarcastic"
    case funny = "Funny"
    case cute = "Cute"
    case encouraging = "Encouraging"
    case coaching = "Coaching"

    var id: String { rawValue }

    /// Display name for UI.
    var displayName: String { rawValue }

    /// SF Symbol representing the attitude.
    var symbol: SFSymbol {
        switch self {
        case .neutral: return .faceSmiling
        case .sarcastic: return .theatermasksFill
        case .funny: return .partyPopperFill
        case .cute: return .heartFill
        case .encouraging: return .handThumbsupFill
        case .coaching: return .clipboard
        }
    }

    /// Description text for selection UI.
    var description: String {
        switch self {
        case .neutral: return "Straightforward and balanced"
        case .sarcastic: return "Playfully witty remarks"
        case .funny: return "Humorous and lighthearted"
        case .cute: return "Sweet and supportive"
        case .encouraging: return "Motivational and positive"
        case .coaching: return "Professional feedback"
        }
    }
}
