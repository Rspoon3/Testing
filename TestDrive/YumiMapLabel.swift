import CoreGraphics
import SwiftUI

/// A text label drawn on Yumi's map (level numbers, XP rewards, etc.).
///
/// Positions are authored in `YumiMapPath.viewBox` coordinates so they can
/// be scaled into any rendering rect. Each position matches the top-leading
/// of the corresponding glyph cluster in `yumi-map-full-svg.svg`.
struct YumiMapLabel: Identifiable, Hashable {

    // MARK: - Style

    /// Visual style for a label, mirroring the source SVG.
    enum Style: Hashable {
        /// Smaller dark-brown reward text near a progress dot.
        case xp
        /// Larger dark-brown level/checkpoint text near a primary waypoint.
        case level
        /// Larger navy text used for the final/highlighted checkpoint.
        case levelHighlighted

        /// Point size in viewBox coordinates (scaled at render time).
        var fontSize: CGFloat {
            switch self {
            case .xp: 11
            case .level, .levelHighlighted: 14
            }
        }

        var fontWeight: Font.Weight {
            switch self {
            case .xp: .semibold
            case .level, .levelHighlighted: .bold
            }
        }
    }

    // MARK: - Variables

    let id: Int
    /// Top-leading position of the label in `YumiMapPath.viewBox` coordinates.
    let position: CGPoint
    let text: String
    let style: Style
}

// MARK: - Default Data

extension Array where Element == YumiMapLabel {
    /// All 24 labels from `yumi-map-full-svg.svg`, ordered from the bottom
    /// of the map upward. Strings are placeholders — replace with real
    /// level / XP values from your data layer.
    static let yumiMap: [YumiMapLabel] = [
        // Level checkpoints (bottom-up)
        .init(id: 0, position: CGPoint(x: 147.968, y: 2183.7), text: "Level 1", style: .level),
        .init(id: 1, position: CGPoint(x: 329.968, y: 1991.7), text: "Level 2", style: .level),
        .init(id: 2, position: CGPoint(x: 126.968, y: 1821.7), text: "Level 3", style: .level),
        .init(id: 3, position: CGPoint(x: 343.968, y: 1595.7), text: "Level 4", style: .level),
        .init(id: 4, position: CGPoint(x: 138.968, y: 1486.7), text: "Level 5", style: .level),
        .init(id: 5, position: CGPoint(x: 236.968, y: 1211.7), text: "Level 6", style: .level),
        .init(id: 6, position: CGPoint(x: 118.968, y: 1027.7), text: "Level 7", style: .level),
        .init(id: 7, position: CGPoint(x: 222.968, y: 890.696), text: "Level 8", style: .level),
        .init(id: 8, position: CGPoint(x: 126.968, y: 640.696), text: "Level 9", style: .level),
        .init(id: 9, position: CGPoint(x: 342.968, y: 456.696), text: "Level 10", style: .level),
        .init(id: 10, position: CGPoint(x: 290.968, y: 299.696), text: "Level 11", style: .level),
        .init(id: 11, position: CGPoint(x: 130.768, y: 64.432), text: "Level 12", style: .level),

        // Final / highlighted checkpoint (navy in source)
        .init(id: 12, position: CGPoint(x: 122.968, y: 105.696), text: "Final", style: .levelHighlighted),

        // XP rewards along the route (bottom-up)
        .init(id: 13, position: CGPoint(x: 263.896, y: 2152.65), text: "+10 XP", style: .xp),
        .init(id: 14, position: CGPoint(x: 179.896, y: 1959.65), text: "+10 XP", style: .xp),
        .init(id: 15, position: CGPoint(x: 217.896, y: 1694.65), text: "+10 XP", style: .xp),
        .init(id: 16, position: CGPoint(x: 180.84, y: 1599.86), text: "+10 XP", style: .xp),
        .init(id: 17, position: CGPoint(x: 195.84, y: 1386.86), text: "+10 XP", style: .xp),
        .init(id: 18, position: CGPoint(x: 294.84, y: 1117.86), text: "+10 XP", style: .xp),
        .init(id: 19, position: CGPoint(x: 264.144, y: 1006.91), text: "+10 XP", style: .xp),
        .init(id: 20, position: CGPoint(x: 235.144, y: 775.912), text: "+10 XP", style: .xp),
        .init(id: 21, position: CGPoint(x: 193.144, y: 553.912), text: "+10 XP", style: .xp),
        .init(id: 22, position: CGPoint(x: 202.896, y: 407.648), text: "+10 XP", style: .xp),
        .init(id: 23, position: CGPoint(x: 321.896, y: 175.648), text: "+10 XP", style: .xp),
    ]
}
