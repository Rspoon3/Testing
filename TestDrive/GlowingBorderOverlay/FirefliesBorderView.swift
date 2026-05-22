//
//  FirefliesBorderView.swift
//  TestDrive
//

import SwiftUI
import Vortex

/// Soft glowing fireflies drifting across the whole screen, tinted with the chosen color.
///
/// The stock `.fireflies` preset emits inside `.ellipse(radius: 0.5)`, which fills
/// only the middle of the screen. We swap the shape to a full-screen box so the
/// flicker spreads edge-to-edge.
struct FirefliesBorderView: View {
    let color: Color

    @State private var system: VortexSystem = fullscreenFireflies()

    // MARK: - Body

    var body: some View {
        VortexView(system) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .blur(radius: 3)
                .tag("circle")
        }
        .ignoresSafeArea()
    }

    // MARK: - Private Helpers

    /// A unique copy of `.fireflies` reshaped to emit across the whole screen.
    private static func fullscreenFireflies() -> VortexSystem {
        let system = VortexSystem.fireflies.makeUniqueCopy()
        system.shape = .box(width: 1, height: 1)
        return system
    }
}

#Preview {
    FirefliesBorderView(color: .yellow)
        .frame(width: 800, height: 500)
        .background(.black)
}
