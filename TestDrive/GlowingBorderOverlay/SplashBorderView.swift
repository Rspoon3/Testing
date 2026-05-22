//
//  SplashBorderView.swift
//  TestDrive
//

import SwiftUI
import Vortex

/// Small splashes of droplets kicking up from the bottom edge — designed to
/// pair with the rain effect but looks acceptable on its own.
///
/// Vortex's stock `.splash` preset already lives at the bottom of the screen
/// (`position: [0.5, 1]`, `shape: .box(width: 1, height: 0)`), so no shape
/// customization is needed. The secondary droplet system's `colors` are
/// overridden so the user's chosen color drives the splash tint at three
/// opacities, matching the spirit of the default blueish palette.
///
/// Per Vortex docs the `"circle"` tag must use `.blendMode(.plusLighter)`.
struct SplashBorderView: View {
    let color: Color

    @State private var system: VortexSystem

    // MARK: - Initializer

    init(color: Color) {
        self.color = color
        _system = State(initialValue: Self.tintedSplash(color: color))
    }

    // MARK: - Body

    var body: some View {
        VortexView(system) {
            Circle()
                .fill(.white)
                .frame(width: 16, height: 16)
                .blendMode(.plusLighter)
                .tag("circle")
        }
        .ignoresSafeArea()
    }

    // MARK: - Private Helpers

    /// A unique copy of `.splash` whose secondary droplet `colors` are tinted
    /// from the supplied color at three opacities.
    private static func tintedSplash(color: Color) -> VortexSystem {
        let system = VortexSystem.splash.makeUniqueCopy()
        // Deep-copy secondaries before mutating so we don't clobber the static preset.
        system.secondarySystems = system.secondarySystems.map { $0.makeUniqueCopy() }
        let tint = VortexSystem.Color(swiftUI: color)
        for secondary in system.secondarySystems {
            secondary.colors = .random(tint.opacity(0.7), tint.opacity(0.6), tint.opacity(0.5))
        }
        return system
    }
}

#Preview {
    SplashBorderView(color: .blue)
        .frame(width: 800, height: 500)
        .background(.black)
}
