//
//  FakeThreeDBadgeView.swift
//  TestDrive
//

import SwiftUI

/// Approach 1 — pure SwiftUI. `rotation3DEffect` for the spin, a masked gradient
/// for the sheen, a real reverse swapped in past 90°.
///
/// No 3D framework, no assets, no shader. The cheapest thing that reads as a
/// spinning medallion, and the only approach here that is safe to put in a
/// scrolling grid of fifty cells.
struct FakeThreeDBadgeView: View {
    private let badge: Badge
    private let angle: Double
    private let tilt: SIMD2<Double>

    // MARK: - Initializer

    /// Creates the badge.
    /// - Parameters:
    ///   - badge: The badge to draw.
    ///   - angle: The spin angle, in degrees.
    ///   - tilt: Device tilt, driving the sheen independently of the spin.
    init(badge: Badge, angle: Double, tilt: SIMD2<Double>) {
        self.badge = badge
        self.angle = angle
        self.tilt = tilt
    }

    // MARK: - Body

    var body: some View {
        BadgeFlip(angle: angle) {
            struck { BadgeFaceView(badge: badge) }
        } back: {
            struck { BadgeBackView(badge: badge) }
        }
    }

    // MARK: - Private Views

    /// Clips a face to the disc, adds the rim and lays the highlight over it.
    private func struck(_ face: () -> some View) -> some View {
        face()
            .overlay { sheen }
            .clipShape(.circle)
            .overlay {
                Circle()
                    .strokeBorder(badge.finish.rimColor, lineWidth: 4)
            }
    }

    /// The specular band. The whole illusion lives here.
    private var sheen: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.1), location: 0.38),
                    .init(color: .white.opacity(0.85), location: 0.5),
                    .init(color: .white.opacity(0.1), location: 0.62),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: width * 2.4)
            // Two inputs, one highlight: the spin sweeps it across, the tilt nudges
            // it. Both are needed — spin alone looks scripted, tilt alone looks static.
            .offset(x: -width * 0.7 + sheenOffset(width: width))
            .blendMode(.overlay)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Private Helpers

    /// Where the highlight sits, given the spin and the tilt.
    private func sheenOffset(width: CGFloat) -> CGFloat {
        let fromSpin = sin(angle * .pi / 180) * width * 0.55
        let fromTilt = CGFloat(tilt.x) * width * 0.4
        return fromSpin + fromTilt
    }
}
