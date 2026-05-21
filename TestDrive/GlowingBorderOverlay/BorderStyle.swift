//
//  BorderStyle.swift
//  TestDrive
//

import Foundation

/// The visual treatment used by the meeting-warning overlay.
///
/// Add a new case here and handle it in ``BorderOverlay`` — call sites stay unchanged.
enum BorderStyle: String, CaseIterable, Identifiable, Hashable {
    /// A solid colored border that pulses outward — honours `glowColor`.
    case colored

    /// A Siri-style multicolored mesh gradient glow at the screen edges. Ignores `glowColor`.
    case glow

    /// A flock of bird-like boids that swarm across the desktop and chase the cursor. Honours `glowColor`.
    case boids

    var id: String { rawValue }

    /// A human-readable title suitable for the settings picker.
    var title: String {
        switch self {
        case .colored: "Colored border"
        case .glow: "Glow"
        case .boids: "Birds"
        }
    }

    /// Whether this style honours the user's chosen glow color.
    var usesGlowColor: Bool {
        switch self {
        case .colored, .boids: true
        case .glow: false
        }
    }

    /// The label to show next to the color picker for this style.
    var colorPickerLabel: String {
        switch self {
        case .colored: "Border color"
        case .glow: "Glow color"
        case .boids: "Birds color"
        }
    }
}
