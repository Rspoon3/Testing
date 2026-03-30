import SwiftUI

/// A labeled color slot for the color picker UI.
struct ColorSlot: Identifiable {
    let id: String
    var color: Color

    /// Creates a labeled color slot.
    /// - Parameters:
    ///   - label: The display label for the picker.
    ///   - color: The default color value.
    init(_ label: String, color: Color) {
        self.id = label
        self.color = color
    }
}

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
    case solidGradient
    case meshGradient

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
        case .solidGradient: "Gradient"
        case .meshGradient: "Mesh Gradient"
        }
    }

    /// Default color slots for this style. Index 0/1 are gradient colors, additional slots are accent colors.
    var defaultColors: [ColorSlot] {
        switch self {
        case .purplePlus:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.45, green: 0.2, blue: 0.75)),
                ColorSlot("Gradient End", color: Color(red: 0.35, green: 0.15, blue: 0.65)),
                ColorSlot("Pattern", color: .white)
            ]
        case .gradientBubbles:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.6, green: 0.2, blue: 0.8)),
                ColorSlot("Gradient End", color: Color(red: 0.9, green: 0.3, blue: 0.5))
            ]
        case .greenClovers:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.9, green: 0.96, blue: 0.88)),
                ColorSlot("Gradient End", color: Color(red: 0.85, green: 0.94, blue: 0.82)),
                ColorSlot("Clover", color: Color(red: 0.3, green: 0.65, blue: 0.35))
            ]
        case .mintBlobs:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.82, green: 0.95, blue: 0.88)),
                ColorSlot("Gradient End", color: Color(red: 0.75, green: 0.92, blue: 0.85)),
                ColorSlot("Accent", color: Color(red: 0.55, green: 0.85, blue: 0.65))
            ]
        case .sunsetWaves:
            [
                ColorSlot("Gradient Start", color: Color(red: 1.0, green: 0.6, blue: 0.3)),
                ColorSlot("Gradient Mid", color: Color(red: 0.95, green: 0.35, blue: 0.5)),
                ColorSlot("Gradient End", color: Color(red: 0.6, green: 0.2, blue: 0.7))
            ]
        case .oceanDots:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.1, green: 0.6, blue: 0.85)),
                ColorSlot("Gradient End", color: Color(red: 0.15, green: 0.35, blue: 0.7)),
                ColorSlot("Dots", color: .cyan)
            ]
        case .warmConfetti:
            [
                ColorSlot("Gradient Start", color: Color(red: 1.0, green: 0.85, blue: 0.4)),
                ColorSlot("Gradient End", color: Color(red: 1.0, green: 0.65, blue: 0.3))
            ]
        case .neonGrid:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.08, green: 0.08, blue: 0.18)),
                ColorSlot("Gradient End", color: Color(red: 0.12, green: 0.05, blue: 0.25)),
                ColorSlot("Grid", color: .cyan)
            ]
        case .radialBurst:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.45, green: 0.2, blue: 0.75)),
                ColorSlot("Gradient End", color: Color(red: 0.3, green: 0.1, blue: 0.55)),
                ColorSlot("Rays", color: .white)
            ]
        case .waveform:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.1, green: 0.3, blue: 0.7)),
                ColorSlot("Gradient End", color: Color(red: 0.05, green: 0.15, blue: 0.5)),
                ColorSlot("Waves", color: .white)
            ]
        case .cosmicSpace:
            [
                ColorSlot("Gradient Start", color: Color(red: 0.08, green: 0.05, blue: 0.2)),
                ColorSlot("Gradient End", color: Color(red: 0.02, green: 0.01, blue: 0.08)),
                ColorSlot("Nebula", color: Color(red: 0.4, green: 0.1, blue: 0.6))
            ]
        case .solidGradient:
            [
                ColorSlot("Color 1", color: Color(red: 0.95, green: 0.3, blue: 0.4)),
                ColorSlot("Color 2", color: Color(red: 0.6, green: 0.2, blue: 0.8)),
                ColorSlot("Color 3", color: Color(red: 0.2, green: 0.4, blue: 0.9))
            ]
        case .meshGradient:
            [
                ColorSlot("Top Left", color: Color(red: 1.0, green: 0.3, blue: 0.4)),
                ColorSlot("Top Right", color: Color(red: 0.3, green: 0.8, blue: 1.0)),
                ColorSlot("Bottom Left", color: Color(red: 0.9, green: 0.6, blue: 0.1)),
                ColorSlot("Bottom Right", color: Color(red: 0.4, green: 0.2, blue: 0.9))
            ]
        }
    }

    /// Whether the style supports an optional SF Symbol overlay.
    var supportsSymbolOverlay: Bool {
        switch self {
        case .solidGradient, .meshGradient: true
        default: false
        }
    }
}
