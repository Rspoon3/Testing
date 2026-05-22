//
//  FireBorderView.swift
//  TestDrive
//

import AppKit
import SwiftUI
import Vortex

/// Flames licking up from the bottom edge of the screen, tinted with the chosen color.
///
/// Vortex's stock `.fire` preset emits from a narrow strip at screen center
/// (`shape: .box(width: 0.1, height: 0)`) and rises upward. To "set the bottom
/// on fire" we widen the strip to the full screen width and move the position
/// to the bottom edge. The `colors` ramp is overridden so the user's chosen
/// color drives the flame, fading out at the top of each particle's life.
///
/// Per Vortex docs the `"circle"` tag must use `.blendMode(.plusLighter)`.
struct FireBorderView: View {
    let color: Color

    @State private var system: VortexSystem

    // MARK: - Initializer

    init(color: Color) {
        self.color = color
        _system = State(initialValue: Self.bottomFire(color: color))
    }

    // MARK: - Body

    var body: some View {
        // Particle render size = `tag_frame × system.size`, in absolute points.
        // Scale the tag frame by canvas width so the flames stay visually tight
        // on big displays (where a fixed 32pt circle would look pinprick-thin).
        GeometryReader { proxy in
            let particle = max(24, proxy.size.width / 50)
            VortexView(system) {
                Circle()
                    .fill(.white)
                    .frame(width: particle, height: particle)
                    .blendMode(.plusLighter)
                    .tag("circle")
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Private Helpers

    /// A unique copy of `.fire` placed along the bottom edge and tinted via a
    /// color→transparent ramp built from the supplied color.
    ///
    /// The emitter sits just above `y = 1` so the dock (which is at a lower
    /// window level but still visually distinct) doesn't hide the densest part
    /// of the fire — flames travel upward from a strip a hair above the floor.
    private static func bottomFire(color: Color) -> VortexSystem {
        let system = VortexSystem.fire.makeUniqueCopy()
        system.shape = .box(width: 1, height: 0)
        system.position = [0.5, 0.92]
        let tint = VortexSystem.Color(swiftUI: color)
        system.colors = .ramp(tint, tint, tint, tint.opacity(0))
        return system
    }
}

#Preview {
    FireBorderView(color: .orange)
        .frame(width: 800, height: 500)
        .background(.black)
}
