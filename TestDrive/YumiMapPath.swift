import SwiftUI

/// The winding dashed route from `yumi-map-full-svg.svg`, expressed as a SwiftUI `Shape`.
///
/// The path is authored in the original SVG coordinate space (386 × 2197) and
/// scaled to fit the rect that SwiftUI hands to `path(in:)`. Apply a dashed
/// stroke (e.g. `StrokeStyle(lineWidth: 4, dash: [12, 12])`) to match the asset.
struct YumiMapPath: Shape {
    /// Original SVG viewBox the curves were authored in.
    static let viewBox = CGSize(width: 386, height: 2197)

    // MARK: - Body

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sx = rect.width / Self.viewBox.width
        let sy = rect.height / Self.viewBox.height

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        // Segment 1 — bottom of the map
        path.move(to: p(101.368, 2142.5))
        path.addCurve(to: p(318.37, 2039.5),
                      control1: p(192.368, 2181.5),
                      control2: p(328.799, 2108.12))
        path.addCurve(to: p(115.369, 1851),
                      control1: p(302.869, 1937.5),
                      control2: p(172.626, 1929.17))
        path.addCurve(to: p(267.868, 1651),
                      control1: p(89.3673, 1815.5),
                      control2: p(68.3672, 1687))
        path.addCurve(to: p(325.867, 1579),
                      control1: p(288.701, 1644.5),
                      control2: p(333.367, 1625.5))

        // Segment 2
        path.move(to: p(324.339, 1568.5))
        path.addCurve(to: p(107.337, 1465.5),
                      control1: p(233.339, 1607.5),
                      control2: p(96.9081, 1534.12))
        path.addCurve(to: p(310.338, 1277),
                      control1: p(122.838, 1363.5),
                      control2: p(253.081, 1355.17))
        path.addCurve(to: p(157.839, 1077),
                      control1: p(336.34, 1241.5),
                      control2: p(357.34, 1113))
        path.addCurve(to: p(99.8398, 1005),
                      control1: p(137.006, 1070.5),
                      control2: p(92.3398, 1051.5))

        // Segment 3
        path.move(to: p(101.368, 994.5))
        path.addCurve(to: p(318.37, 891.5),
                      control1: p(192.368, 1033.5),
                      control2: p(328.799, 960.123))
        path.addCurve(to: p(115.37, 703),
                      control1: p(302.869, 789.5),
                      control2: p(172.626, 781.171))
        path.addCurve(to: p(267.869, 503),
                      control1: p(89.3678, 667.5),
                      control2: p(68.3677, 539))
        path.addCurve(to: p(325.868, 431),
                      control1: p(288.701, 496.5),
                      control2: p(333.368, 477.5))

        // Segment 4 — top of the map
        path.move(to: p(324.483, 424.914))
        path.addCurve(to: p(107.201, 363.764),
                      control1: p(233.365, 448.069),
                      control2: p(96.7585, 404.505))
        path.addCurve(to: p(310.463, 251.851),
                      control1: p(122.722, 303.206),
                      control2: p(253.133, 298.261))
        path.addCurve(to: p(157.768, 133.112),
                      control1: p(336.499, 230.775),
                      control2: p(357.526, 154.485))
        path.addCurve(to: p(99.694, 90.3652),
                      control1: p(136.908, 129.253),
                      control2: p(92.1844, 117.972))

        return path
    }
}

#Preview {
    YumiMapPath()
        .stroke(
            Color(red: 0x51 / 255, green: 0x9E / 255, blue: 0x98 / 255),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [12, 12])
        )
        .aspectRatio(YumiMapPath.viewBox.width / YumiMapPath.viewBox.height, contentMode: .fit)
        .padding()
}
