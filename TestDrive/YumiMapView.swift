import SwiftUI

/// Renders Yumi's full map: the dashed `YumiMapPath` with all waypoint
/// circles overlaid in the correct visual styles.
///
/// The view preserves the asset's 386 × 2197 aspect ratio and scales every
/// element (path, line widths, dashes, circles, strokes) uniformly so the
/// map looks consistent at any size.
struct YumiMapView: View {
    /// Size of the clip rect used for each Yumi instance in the source SVG,
    /// in viewBox coordinates.
    private static let mascotSize = CGSize(width: 72.0513, height: 74.1704)

    /// Rotation applied to each Yumi instance in the source SVG.
    private static let mascotRotation = Angle.degrees(4.70397)

    /// Top-leading positions for the four Yumi mascots in the source SVG,
    /// in viewBox coordinates. Mirrors each instance's `translate(...) rotate(...)`.
    private static let mascotPositions: [CGPoint] = [
        CGPoint(x: 56.0826, y: 0),
        CGPoint(x: 259.824, y: 620.98),
        CGPoint(x: 99.082, y: 1234),
        CGPoint(x: 260.082, y: 1827),
    ]

    private let waypoints: [YumiMapWaypoint]
    private let labels: [YumiMapLabel]
    private let routeColor: Color
    private let highlightColor: Color
    private let labelColor: Color
    private let labelHighlightColor: Color

    // MARK: - Initializer

    /// Creates a `YumiMapView`.
    /// - Parameters:
    ///   - waypoints: Waypoints to draw on top of the route. Defaults to the full asset set.
    ///   - labels: Text labels (levels, XP rewards) to draw over the map. Defaults to the full asset set.
    init(
        waypoints: [YumiMapWaypoint] = .yumiMap,
        labels: [YumiMapLabel] = .yumiMap
    ) {
        self.waypoints = waypoints
        self.labels = labels
        self.routeColor = Color(red: 0x51 / 255, green: 0x9E / 255, blue: 0x98 / 255)
        self.highlightColor = Color(red: 0x77 / 255, green: 0xCF / 255, blue: 0xC8 / 255)
        self.labelColor = Color(red: 0x4B / 255, green: 0x3B / 255, blue: 0x24 / 255)
        self.labelHighlightColor = Color(red: 0x19 / 255, green: 0x17 / 255, blue: 0x4D / 255)
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

                ForEach(Array(Self.mascotPositions.enumerated()), id: \.offset) { _, position in
                    mascotView(at: position, scale: scale)
                }

                ForEach(labels) { label in
                    labelView(for: label, scale: scale)
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

    /// A text label drawn at its top-leading viewBox position.
    private func labelView(for label: YumiMapLabel, scale: CGFloat) -> some View {
        Text(label.text)
            .font(.system(size: label.style.fontSize * scale, weight: label.style.fontWeight))
            .foregroundStyle(label.style == .levelHighlighted ? labelHighlightColor : labelColor)
            .fixedSize()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: label.position.x * scale, y: label.position.y * scale)
    }

    /// The Yumi mascot drawn at a top-leading viewBox position with the
    /// asset's authored rotation. Mirrors SVG's `translate(x, y) rotate(a)`
    /// by rotating around the top-leading anchor and then offsetting.
    private func mascotView(at position: CGPoint, scale: CGFloat) -> some View {
        Image(.yumi)
            .resizable()
            .frame(
                width: Self.mascotSize.width * scale,
                height: Self.mascotSize.height * scale
            )
            .rotationEffect(Self.mascotRotation, anchor: .topLeading)
            .offset(x: position.x * scale, y: position.y * scale)
    }
}

#Preview {
    ScrollView {
        YumiMapView()
            .padding()
    }
}
