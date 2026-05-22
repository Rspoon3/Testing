//
//  BorderOverlay.swift
//  TestDrive
//

import AppKit
import SwiftUI

/// Dispatches to the concrete border view for a given ``BorderStyle``.
///
/// Sits between the controller and the per-style views so adding a new
/// ``BorderStyle`` case only requires extending the switch below.
struct BorderOverlay: View {
    let style: BorderStyle
    let color: Color
    let screen: NSScreen?
    /// When `style` is `.fireworks`, controls whether explosions use the chosen
    /// color, a varied palette, or a new random color per launch.
    let fireworksColorMode: FireworksColorMode

    // MARK: - Body

    var body: some View {
        switch style {
        case .colored:
            GlowingBorderView(color: color)
        case .glow:
            SiriGlowBorderView()
        case .boids:
            BoidsBorderView(color: color, screen: screen)
        case .confetti:
            ConfettiBorderView()
        case .fireflies:
            FirefliesBorderView(color: color)
        case .rain:
            RainBorderView(color: color)
        case .snow:
            SnowBorderView(color: color)
        case .magic:
            MagicBorderView(color: color)
        case .fireworks:
            FireworksBorderView(colorMode: fireworksColorMode, color: color)
        case .fire:
            FireBorderView(color: color)
        case .smoke:
            SmokeBorderView(color: color)
        case .splash:
            SplashBorderView(color: color)
        case .bouncyBalls:
            BallsBorderView()
        case .random:
            // Defensive — the controller resolves `.random` before constructing
            // this view, so the same concrete effect renders across every screen.
            GlowingBorderView(color: color)
        }
    }
}
