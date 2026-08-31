//
//  BadgeFlip.swift
//  TestDrive
//

import SwiftUI

/// Spins a two-sided badge, swapping faces as it turns away from the viewer.
///
/// Shared by the three flat approaches so the flip behaves identically in all of
/// them — the only thing that should differ between those tabs is how the metal is
/// shaded.
struct BadgeFlip<Front: View, Back: View>: View {
    private let angle: Double
    private let front: () -> Front
    private let back: () -> Back

    // MARK: - Initializer

    /// Creates a flippable badge.
    /// - Parameters:
    ///   - angle: The spin angle, in degrees.
    ///   - front: The obverse.
    ///   - back: The reverse.
    init(
        angle: Double,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self.angle = angle
        self.front = front
        self.back = back
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isShowingBack(angle: angle) {
                // Counter-flipped, so the reverse is not itself mirrored while it is
                // the side facing the viewer.
                back()
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                front()
            }
        }
        .rotation3DEffect(
            .degrees(angle),
            axis: (x: 0, y: 1, z: 0),
            // Well above the 1/6 default. The badge is a wide, flat object, and a
            // shallow perspective is what makes it look like a rotating disc rather
            // than a sliding card.
            perspective: 0.75
        )
    }
}

/// Whether the reverse is the side facing the viewer.
///
/// A free function rather than a method so the 3D tabs can ask the same question
/// without constructing a `BadgeFlip`.
/// - Parameter angle: The spin angle, in degrees. May wind past 360.
/// - Returns: `true` between 90° and 270°.
func isShowingBack(angle: Double) -> Bool {
    let normalized = (angle.truncatingRemainder(dividingBy: 360) + 360)
        .truncatingRemainder(dividingBy: 360)
    return normalized > 90 && normalized < 270
}
