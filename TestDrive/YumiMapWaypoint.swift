import CoreGraphics

/// A waypoint along Yumi's map route.
///
/// Positions are authored in the original SVG viewBox coordinate space
/// (`YumiMapPath.viewBox`), so consumers must scale them when drawing
/// into a different rect.
struct YumiMapWaypoint: Identifiable, Hashable {

    // MARK: - Kind

    /// Visual style for a waypoint, mirroring the SVG asset.
    enum Kind: Hashable {
        /// Solid teal dot marking the current location (radius 11.5).
        case current
        /// White-filled, teal-stroked major checkpoint (radius 10).
        case primary
        /// White-filled, teal-stroked progress dot between checkpoints (radius 7.5).
        case secondary
        /// Teal-filled, teal-stroked progress dot (radius 7.5) — used for the
        /// next-up dot adjacent to the current location.
        case secondaryHighlighted
    }

    // MARK: - Variables

    let id: Int
    /// Position in `YumiMapPath.viewBox` coordinates.
    let position: CGPoint
    let kind: Kind

    /// Radius of the waypoint in viewBox coordinates.
    var radius: CGFloat {
        switch kind {
        case .current: 11.5
        case .primary: 10
        case .secondary, .secondaryHighlighted: 7.5
        }
    }
}

// MARK: - Default Data

extension Array where Element == YumiMapWaypoint {
    /// All 56 waypoints from `yumi-map-full-svg.svg`, in source order.
    static let yumiMap: [YumiMapWaypoint] = [
        // Current location
        .init(id: 0, position: CGPoint(x: 151.5, y: 2152.5), kind: .current),

        // Primary checkpoints (top-down through the asset)
        .init(id: 1, position: CGPoint(x: 301.5, y: 1992.5), kind: .primary),
        .init(id: 2, position: CGPoint(x: 100.5, y: 1807.5), kind: .primary),
        .init(id: 3, position: CGPoint(x: 324.5, y: 1569.5), kind: .primary),
        .init(id: 4, position: CGPoint(x: 325.5, y: 433.5), kind: .primary),
        .init(id: 5, position: CGPoint(x: 110.5, y: 1466.5), kind: .primary),
        .init(id: 6, position: CGPoint(x: 324.5, y: 1191.5), kind: .primary),
        .init(id: 7, position: CGPoint(x: 313.5, y: 869.5), kind: .primary),
        .init(id: 8, position: CGPoint(x: 104.5, y: 614.5), kind: .primary),
        .init(id: 9, position: CGPoint(x: 271.5, y: 276.5), kind: .primary),
        .init(id: 10, position: CGPoint(x: 98.5, y: 91.5), kind: .primary),
        .init(id: 11, position: CGPoint(x: 104.5, y: 996.5), kind: .primary),

        // Progress dots — first one is the teal-filled "next up"
        .init(id: 12, position: CGPoint(x: 201, y: 2148), kind: .secondaryHighlighted),
        .init(id: 13, position: CGPoint(x: 245, y: 2132), kind: .secondary),
        .init(id: 14, position: CGPoint(x: 290, y: 2105), kind: .secondary),
        .init(id: 15, position: CGPoint(x: 318, y: 2063), kind: .secondary),
        .init(id: 16, position: CGPoint(x: 272, y: 1960), kind: .secondary),
        .init(id: 17, position: CGPoint(x: 230, y: 1934), kind: .secondary),
        .init(id: 18, position: CGPoint(x: 186, y: 1911), kind: .secondary),
        .init(id: 19, position: CGPoint(x: 131, y: 1872), kind: .secondary),
        .init(id: 20, position: CGPoint(x: 112, y: 1741), kind: .secondary),
        .init(id: 21, position: CGPoint(x: 140, y: 1706), kind: .secondary),
        .init(id: 22, position: CGPoint(x: 201, y: 1669), kind: .secondary),
        .init(id: 23, position: CGPoint(x: 268, y: 1651), kind: .secondary),
        .init(id: 24, position: CGPoint(x: 274, y: 1579), kind: .secondary),
        .init(id: 25, position: CGPoint(x: 228, y: 1574), kind: .secondary),
        .init(id: 26, position: CGPoint(x: 180, y: 1558), kind: .secondary),
        .init(id: 27, position: CGPoint(x: 137, y: 1532), kind: .secondary),
        .init(id: 28, position: CGPoint(x: 124, y: 1421), kind: .secondary),
        .init(id: 29, position: CGPoint(x: 175, y: 1373), kind: .secondary),
        .init(id: 30, position: CGPoint(x: 236, y: 1337), kind: .secondary),
        .init(id: 31, position: CGPoint(x: 309, y: 1280), kind: .secondary),
        .init(id: 32, position: CGPoint(x: 302, y: 1147), kind: .secondary),
        .init(id: 33, position: CGPoint(x: 269, y: 1113), kind: .secondary),
        .init(id: 34, position: CGPoint(x: 227, y: 1095), kind: .secondary),
        .init(id: 35, position: CGPoint(x: 157, y: 1077), kind: .secondary),
        .init(id: 36, position: CGPoint(x: 175, y: 1002), kind: .secondary),
        .init(id: 37, position: CGPoint(x: 247, y: 984), kind: .secondary),
        .init(id: 38, position: CGPoint(x: 287, y: 958), kind: .secondary),
        .init(id: 39, position: CGPoint(x: 318, y: 916), kind: .secondary),
        .init(id: 40, position: CGPoint(x: 269, y: 814), kind: .secondary),
        .init(id: 41, position: CGPoint(x: 209, y: 775), kind: .secondary),
        .init(id: 42, position: CGPoint(x: 166, y: 750), kind: .secondary),
        .init(id: 43, position: CGPoint(x: 114, y: 704), kind: .secondary),
        .init(id: 44, position: CGPoint(x: 141, y: 558), kind: .secondary),
        .init(id: 45, position: CGPoint(x: 178, y: 531), kind: .secondary),
        .init(id: 46, position: CGPoint(x: 222, y: 513), kind: .secondary),
        .init(id: 47, position: CGPoint(x: 292, y: 494), kind: .secondary),
        .init(id: 48, position: CGPoint(x: 251, y: 431), kind: .secondary),
        .init(id: 49, position: CGPoint(x: 179, y: 418), kind: .secondary),
        .init(id: 50, position: CGPoint(x: 119, y: 344), kind: .secondary),
        .init(id: 51, position: CGPoint(x: 204, y: 301), kind: .secondary),
        .init(id: 52, position: CGPoint(x: 326, y: 233), kind: .secondary),
        .init(id: 53, position: CGPoint(x: 297, y: 172), kind: .secondary),
        .init(id: 54, position: CGPoint(x: 231, y: 145), kind: .secondary),
        .init(id: 55, position: CGPoint(x: 159, y: 131), kind: .secondary),
    ]
}
