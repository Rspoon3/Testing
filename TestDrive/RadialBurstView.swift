public import SwiftUI

/// A SwiftUI view that creates a radial burst pattern with alternating colored rays.
///
/// The view creates triangular rays emanating from a center point, alternating between
/// two colors to create a burst effect. The rays extend to fill the entire frame of the view.
public struct RadialBurstView: View {
    /// The number of rays in the burst pattern.
    private let rayCount: Int
    /// The array of colors used for alternating rays.
    private let colors: [Color]
    /// The opacity applied to the burst pattern.
    private let opacity: Double
    /// The center point from which rays emanate.
    private let center: UnitPoint
    /// If provided, the radial burst will animate a full rotation over the given duration.
    private let animationDuration: TimeInterval?

    /// Degrees with which the radial burst is rotated.
    @State private var rotation: Double = 0

    /// Creates a radial burst view with the specified configuration.
    ///
    /// - Parameters:
    ///   - colors: An array of colors used for alternating rays. Should contain at least 2 colors.
    ///   - rayCount: The number of rays to create in the burst pattern.
    ///   - opacity: The opacity to apply to the entire burst pattern.
    ///   - center: The center point from which rays emanate. Defaults to center of the view.
    ///   - animationDuration: If provided, the radial burst will animate a full rotation over the given duration.
    public init(
        colors: [Color],
        rayCount: Int,
        opacity: Double,
        center: UnitPoint = .center,
        animationDuration: TimeInterval? = nil
    ) {
        self.colors = colors
        self.rayCount = rayCount
        self.opacity = opacity
        self.center = center
        self.animationDuration = animationDuration
    }

    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let centerPoint = CGPoint(
                x: center.x * size.width,
                y: center.y * size.height
            )

            // Compute max distance from center to each corner
            let corners = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: size.width, y: 0),
                CGPoint(x: 0, y: size.height),
                CGPoint(x: size.width, y: size.height),
            ]
            let maxRadius = corners.map {
                hypot($0.x - centerPoint.x, $0.y - centerPoint.y)
            }.max() ?? 0

            ZStack {
                ForEach(0..<rayCount, id: \.self) { i in
                    let angle1 = Double(i) / Double(rayCount) * 2 * .pi
                    let angle2 = Double(i + 1) / Double(rayCount) * 2 * .pi

                    let start1 = CGPoint(
                        x: centerPoint.x + CGFloat(cos(angle1)) * maxRadius,
                        y: centerPoint.y + CGFloat(sin(angle1)) * maxRadius
                    )

                    let start2 = CGPoint(
                        x: centerPoint.x + CGFloat(cos(angle2)) * maxRadius,
                        y: centerPoint.y + CGFloat(sin(angle2)) * maxRadius
                    )

                    Path { path in
                        path.move(to: centerPoint)
                        path.addLine(to: start1)
                        path.addLine(to: start2)
                        path.closeSubpath()
                    }
                    .fill(colors[i.isMultiple(of: 2) ? 0 : 1].opacity(opacity))
                }
            }
            .rotationEffect(.degrees(rotation), anchor: center)
            .drawingGroup()
        }
        .ignoresSafeArea(edges: .all)
        .onAppear {

            if let animationDuration {
                withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        ForEach([0.25, 0.5, 0.75], id: \.self) { x in
            Text("This")
                .frame(width: 300, height: 100)
                .background {
                    RadialBurstView(
                        colors: [Color.red, Color.clear],
                        rayCount: 62,
                        opacity: 1,
                        center: UnitPoint(x: x, y: 0.5)
                    )
                    .border(Color.blue)
                    .frame(width: 300, height: 100)
                }
        }
    }
}
#endif
