//
//  BadgeFinish.swift
//  TestDrive
//

import SwiftUI

/// The metal a medallion is struck from.
///
/// One place for the palette so all four rendering approaches are judged on the
/// same colors — if the gold differs between tabs, the comparison is worthless.
enum BadgeFinish: String, CaseIterable, Hashable {
    case gold
    case silver
    case bronze
    case cosmic

    /// The face gradient, dark rim to bright center.
    var faceColors: [Color] {
        switch self {
        case .gold: [.init(red: 0.45, green: 0.30, blue: 0.05), .init(red: 1.0, green: 0.84, blue: 0.35), .init(red: 0.62, green: 0.42, blue: 0.08)]
        case .silver: [.init(red: 0.28, green: 0.30, blue: 0.34), .init(red: 0.93, green: 0.95, blue: 0.98), .init(red: 0.42, green: 0.45, blue: 0.50)]
        case .bronze: [.init(red: 0.32, green: 0.17, blue: 0.08), .init(red: 0.86, green: 0.55, blue: 0.32), .init(red: 0.45, green: 0.24, blue: 0.11)]
        case .cosmic: [.init(red: 0.14, green: 0.06, blue: 0.32), .init(red: 0.60, green: 0.45, blue: 1.0), .init(red: 0.20, green: 0.10, blue: 0.45)]
        }
    }

    /// The engraved symbol's color — a darker cut into the metal.
    var engravingColor: Color {
        switch self {
        case .gold: .init(red: 0.35, green: 0.22, blue: 0.02)
        case .silver: .init(red: 0.22, green: 0.24, blue: 0.28)
        case .bronze: .init(red: 0.24, green: 0.12, blue: 0.05)
        case .cosmic: .init(red: 0.10, green: 0.04, blue: 0.24)
        }
    }

    /// The rim color used for the 3D medallion's edge and the flat views' border.
    var rimColor: Color {
        faceColors[2]
    }

    /// RealityKit's `roughness`. Lower is mirror-like.
    var roughness: Float {
        switch self {
        case .gold: 0.22
        case .silver: 0.14
        case .bronze: 0.34
        case .cosmic: 0.20
        }
    }
}
