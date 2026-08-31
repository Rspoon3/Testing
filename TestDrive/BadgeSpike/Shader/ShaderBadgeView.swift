//
//  ShaderBadgeView.swift
//  TestDrive
//

import SwiftUI

/// Approach 3 — a Metal `layerEffect` faking image-based lighting in screen space.
///
/// The badge is still a flat 2D layer; the shader adds a specular response that
/// tracks device tilt. Cheap enough for a grid, and much closer to metal than a
/// gradient, but the silhouette never changes.
struct ShaderBadgeView: View {
    private let badge: Badge
    private let angle: Double
    private let tilt: SIMD2<Double>

    // MARK: - Initializer

    /// Creates the badge.
    /// - Parameters:
    ///   - badge: The badge to draw.
    ///   - angle: The spin angle, in degrees.
    ///   - tilt: Device tilt, driving the specular highlight.
    init(badge: Badge, angle: Double, tilt: SIMD2<Double>) {
        self.badge = badge
        self.angle = angle
        self.tilt = tilt
    }

    // MARK: - Body

    var body: some View {
        BadgeFlip(angle: angle) {
            lit(BadgeFaceView(badge: badge))
        } back: {
            lit(BadgeBackView(badge: badge))
        }
    }

    // MARK: - Private Views

    /// Runs a face through the specular shader.
    ///
    /// Takes the face as a value rather than a builder closure: the `GeometryReader`
    /// below escapes, and a non-escaping `@ViewBuilder` parameter cannot cross into it.
    private func lit(_ face: some View) -> some View {
        GeometryReader { proxy in
            let size = proxy.size

            face
                .clipShape(.circle)
                .overlay {
                    Circle()
                        .strokeBorder(badge.finish.rimColor, lineWidth: 4)
                }
                .layerEffect(
                    ShaderLibrary.badgeSheen(
                        .float2(size),
                        .float2(Float(tilt.x), Float(tilt.y)),
                        .float(Float(angle * .pi / 180))
                    ),
                    // The shader only ever reads the pixel under `position`, so it
                    // needs no neighbourhood — stating zero lets SwiftUI skip
                    // padding the layer.
                    maxSampleOffset: .zero
                )
        }
    }
}
