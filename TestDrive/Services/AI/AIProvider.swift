import Foundation
import SFSymbols

/// Available AI providers for generating messages.
enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case chatGPT = "ChatGPT"
    case foundationModel = "Foundation Model"

    var id: String { rawValue }

    /// Display name for UI.
    var displayName: String { rawValue }

    /// SF Symbol representing the provider.
    var symbol: SFSymbol {
        switch self {
        case .chatGPT:
            return .cloud
        case .foundationModel:
            return .cpuFill
        }
    }

    /// Description for UI.
    var description: String {
        switch self {
        case .chatGPT:
            return "Cloud-based AI (requires internet)"
        case .foundationModel:
            return "On-device AI (iOS 26+)"
        }
    }

    /// Whether this provider is available on the current device.
    var isAvailable: Bool {
        switch self {
        case .chatGPT:
            return true
        case .foundationModel:
            if #available(iOS 26, *) {
                return true
            }
            return false
        }
    }
}
