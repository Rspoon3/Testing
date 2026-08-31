//
//  GlassBadgeView.swift
//  TestDrive
//

import SwiftUI

/// Approach 2 — iOS 26 Liquid Glass over the flat artwork.
///
/// The bet: `.glassEffect` already computes specular highlights and edge
/// refraction, so layering it over the badge should buy a chrome rim for free with
/// no shader and no 3D. `.interactive()` makes it respond to touch.
///
/// **Finding:** it does not survive `rotation3DEffect`. The glass layer is resolved
/// against the window rather than the rotated content, so past roughly 30° it visibly
/// detaches and slides off the artwork. Face-on it looks good; spinning it does not
/// work, which rules this out for a badge that turns.
struct GlassBadgeView: View {
    private let badge: Badge
    private let angle: Double

    // MARK: - Initializer

    /// Creates the badge.
    /// - Parameters:
    ///   - badge: The badge to draw.
    ///   - angle: The spin angle, in degrees.
    init(badge: Badge, angle: Double) {
        self.badge = badge
        self.angle = angle
    }

    // MARK: - Body

    var body: some View {
        BadgeFlip(angle: angle) {
            glazed { BadgeFaceView(badge: badge) }
        } back: {
            glazed { BadgeBackView(badge: badge) }
        }
    }

    // MARK: - Private Views

    /// Puts the system glass material over a face.
    private func glazed(_ face: () -> some View) -> some View {
        GlassEffectContainer(spacing: 0) {
            face()
                .clipShape(.circle)
                // The glass sits on top of the artwork rather than replacing it, so
                // the engraving stays legible and only the surface treatment changes.
                .glassEffect(.regular.interactive(), in: .circle)
                .overlay {
                    Circle()
                        .strokeBorder(badge.finish.rimColor.opacity(0.8), lineWidth: 3)
                }
        }
    }
}
