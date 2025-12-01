//
//  CircleToLineAnimationView.swift
//  TestDrive
//
//  Created by Claude Code
//

import SwiftUI

/// A view that animates moon phases from a circular arrangement to a horizontal line based on scroll position.
struct CircleToLineAnimationView: View {
    private let moonPhases: [MoonPhase]
    private let scrollProgress: CGFloat

    // MARK: - Initializer

    /// Creates a circle-to-line animation view.
    /// - Parameters:
    ///   - moonPhases: An array of moon phases to display.
    ///   - scrollProgress: The scroll progress (0.0 = line, 1.0 = circle).
    init(moonPhases: [MoonPhase], scrollProgress: CGFloat) {
        self.moonPhases = moonPhases
        self.scrollProgress = scrollProgress
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(moonPhases.enumerated()), id: \.offset) { index, phase in
                    MoonPhaseView(
                        fillPercentage: phase.fillPercentage,
                        color: phase.color,
                        size: 20
                    )
                    .position(positionForMoon(at: index, in: geometry.size))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Private Helpers

    /// Calculates the position for a moon at a given index based on scroll progress.
    /// - Parameters:
    ///   - index: The index of the moon in the array.
    ///   - size: The size of the container.
    /// - Returns: The calculated position for the moon.
    private func positionForMoon(at index: Int, in size: CGSize) -> CGPoint {
        let count = moonPhases.count
        let angle = (2 * .pi / Double(count)) * Double(index) - .pi / 2

        // Circle position - use fixed smaller radius for tighter circle
        let radius: CGFloat = 80
        let circleX = size.width / 2 + cos(angle) * radius
        let circleY = size.height / 2 + sin(angle) * radius

        // Line position - extend outward based on horizontal projection
        // The key: use the SIGN and MAGNITUDE of cos(angle) to determine spacing
        // This makes moons spread outward symmetrically from center

        let lineSpacing: CGFloat = 35 // Base spacing for the line

        // Calculate how far left or right this moon should be on the line
        // Use the X distance from center in the circle, then amplify it
        let circleXOffset = cos(angle) * radius
        let amplificationFactor: CGFloat = 2.5 // How much to spread beyond the circle
        let lineX = size.width / 2 + circleXOffset * amplificationFactor

        // All moons should be at the same Y position (forming a horizontal line)
        let lineY: CGFloat = size.height / 2

        // Interpolate between circle and line based on scroll progress
        // scrollProgress = 0 -> line (extended horizontally), scrollProgress = 1 -> circle
        let x = lineX + (circleX - lineX) * scrollProgress
        let y = lineY + (circleY - lineY) * scrollProgress

        return CGPoint(x: x, y: y)
    }
}

/// Represents a moon phase with fill percentage and color.
struct MoonPhase {
    let fillPercentage: Double
    let color: Color
}

#Preview {
    let moonPhases = [
        MoonPhase(fillPercentage: 0.0, color: .purple),
        MoonPhase(fillPercentage: 0.1, color: .purple),
        MoonPhase(fillPercentage: 0.2, color: .red),
        MoonPhase(fillPercentage: 0.3, color: .red),
        MoonPhase(fillPercentage: 0.4, color: .pink),
        MoonPhase(fillPercentage: 0.5, color: .pink),
        MoonPhase(fillPercentage: 0.6, color: .orange),
        MoonPhase(fillPercentage: 0.7, color: .orange),
        MoonPhase(fillPercentage: 0.8, color: .yellow),
        MoonPhase(fillPercentage: 0.9, color: .yellow),
        MoonPhase(fillPercentage: 1.0, color: .green),
    ]

    VStack {
        Text("Circle (scrollProgress = 0)")
        CircleToLineAnimationView(moonPhases: moonPhases, scrollProgress: 0)
            .frame(height: 300)
            .background(.black)

        Text("Line (scrollProgress = 1)")
        CircleToLineAnimationView(moonPhases: moonPhases, scrollProgress: 1)
            .frame(height: 300)
            .background(.black)
    }
}
