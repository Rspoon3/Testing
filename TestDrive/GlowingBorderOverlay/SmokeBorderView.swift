//
//  SmokeBorderView.swift
//  TestDrive
//

import SwiftUI
import Vortex

/// A slow column of smoke rising from the bottom edge of the screen,
/// tinted with the chosen color.
///
/// Vortex's stock `.smoke` preset emits from a narrow strip
/// (`shape: .box(width: 0.05, height: 0)`) at screen center. We widen the
/// strip to full screen width and pin it to the bottom so smoke billows up
/// from the dock area. The `colors` ramp is overridden to fade from the
/// chosen color to transparent.
struct SmokeBorderView: View {
    let color: Color

    @State private var system: VortexSystem

    // MARK: - Initializer

    init(color: Color) {
        self.color = color
        _system = State(initialValue: Self.bottomSmoke(color: color))
    }

    // MARK: - Body

    var body: some View {
        VortexView(system) {
            Circle()
                .fill(.white)
                .frame(width: 64, height: 64)
                .tag("circle")
        }
        .ignoresSafeArea()
    }

    // MARK: - Private Helpers

    /// A unique copy of `.smoke` placed along the bottom edge and tinted via a
    /// color→transparent ramp built from the supplied color.
    private static func bottomSmoke(color: Color) -> VortexSystem {
        let system = VortexSystem.smoke.makeUniqueCopy()
        system.shape = .box(width: 1, height: 0)
        system.position = [0.5, 1]
        let tint = VortexSystem.Color(swiftUI: color)
        system.colors = .ramp(tint, tint.opacity(0))
        return system
    }
}

#Preview {
    SmokeBorderView(color: .gray)
        .frame(width: 800, height: 500)
        .background(.black)
}
