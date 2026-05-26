//
//  FireworksColorMode.swift
//  TestDrive
//

import Foundation

/// How the fireworks overlay decides what color each explosion is.
enum FireworksColorMode: String, CaseIterable, Identifiable, Hashable, Codable {
    /// Every firework explodes in the user's chosen `glowColor`.
    case fixed

    /// Each particle inside every explosion picks a random color from a palette,
    /// so a single firework reads as a wash of mixed colors.
    case multicolor

    /// Every firework explodes in one solid color, with the color varying
    /// between launches so successive fireworks are different colors.
    case random

    var id: String { rawValue }

    /// A human-readable title suitable for the settings picker.
    var title: String {
        switch self {
        case .fixed: "Selected color"
        case .multicolor: "Multi-color"
        case .random: "Random color"
        }
    }
}
