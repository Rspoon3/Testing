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

    var id: String { rawValue }

    /// A human-readable title suitable for the settings picker.
    var title: String {
        switch self {
        case .colored: "Colored border"
        case .glow: "Glow"
        }
    }
}
