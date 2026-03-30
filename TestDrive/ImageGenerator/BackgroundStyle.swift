import SwiftUI

/// Defines the available background design styles for generated images.
enum BackgroundStyle: String, CaseIterable, Identifiable {
    case purplePlus
    case gradientBubbles
    case greenClovers
    case mintBlobs
    case sunsetWaves
    case oceanDots
    case warmConfetti
    case neonGrid
    case radialBurst
    case waveform
    case cosmicSpace

    var id: String { rawValue }

    /// Display name for the background style.
    var title: String {
        switch self {
        case .purplePlus: "Purple Plus"
        case .gradientBubbles: "Gradient Bubbles"
        case .greenClovers: "Green Clovers"
        case .mintBlobs: "Mint Blobs"
        case .sunsetWaves: "Sunset Waves"
        case .oceanDots: "Ocean Dots"
        case .warmConfetti: "Warm Confetti"
        case .neonGrid: "Neon Grid"
        case .radialBurst: "Radial Burst"
        case .waveform: "Waveform"
        case .cosmicSpace: "Cosmic Space"
        }
    }
}
