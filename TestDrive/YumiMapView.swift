import SwiftUI

/// Renders Yumi's full map: the dashed `YumiMapPath` with all waypoint
/// circles overlaid in the correct visual styles.
///
/// The view preserves the asset's 386 × 2197 aspect ratio and scales every
/// element (path, line widths, dashes, circles, strokes) uniformly so the
/// map looks consistent at any size.
struct YumiMapView: View {
    /// Natural size of the Yumi mascot SVG, used to size the asset in the
    /// scaled map coordinate space.
    private static let mascotSize = CGSize(width: 73, height: 75)

    private let waypoints: [YumiMapWaypoint]
    private let routeColor: Color
    private let highlightColor: Color

    // MARK: - Initializer

    /// Creates a `YumiMapView`.
    /// - Parameter waypoints: Waypoints to draw on top of the route. Defaults to the full asset set.
    init(waypoints: [YumiMapWaypoint] = .yumiMap) {
        self.waypoints = waypoints
        self.routeColor = Color(red: 0x51 / 255, green: 0x9E / 255, blue: 0x98 / 255)
        self.highlightColor = Color(red: 0x77 / 255, green: 0xCF / 255, blue: 0xC8 / 255)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / YumiMapPath.viewBox.width

            ZStack(alignment: .topLeading) {
                YumiMapPath()
                    .stroke(
                        routeColor,
                        style: StrokeStyle(
                            lineWidth: 4 * scale,
                            lineCap: .round,
                            dash: [12 * scale, 12 * scale]
                        )
                    )

                ForEach(waypoints) { waypoint in
                    waypointView(for: waypoint, scale: scale)
                }

                if let current = waypoints.first(where: { $0.kind == .current }) {
                    mascotView(at: current.position, scale: scale)
                }
            }
        }
        .aspectRatio(YumiMapPath.viewBox.width / YumiMapPath.viewBox.height, contentMode: .fit)
    }

    // MARK: - Private Views

    /// A single waypoint circle, sized and positioned in the scaled coordinate space.
    @ViewBuilder
    private func waypointView(for waypoint: YumiMapWaypoint, scale: CGFloat) -> some View {
        let diameter = waypoint.radius * 2 * scale
        let strokeWidth = 3 * scale

        Group {
            switch waypoint.kind {
            case .current:
                Circle()
                    .fill(routeColor)
            case .primary, .secondary:
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(routeColor, lineWidth: strokeWidth))
            case .secondaryHighlighted:
                Circle()
                    .fill(highlightColor)
                    .overlay(Circle().stroke(routeColor, lineWidth: strokeWidth))
            }
        }
        .frame(width: diameter, height: diameter)
        .position(x: waypoint.position.x * scale, y: waypoint.position.y * scale)
    }

    /// The Yumi mascot, drawn so its feet sit on the given map position.
    private func mascotView(at position: CGPoint, scale: CGFloat) -> some View {
        let width = Self.mascotSize.width * scale
        let height = Self.mascotSize.height * scale

        return Image(.yumi)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .position(
                x: position.x * scale,
                y: position.y * scale - height / 2
            )
    }
}

#Preview {
    ScrollView {
        YumiMapView()
            .padding()
    }
}
