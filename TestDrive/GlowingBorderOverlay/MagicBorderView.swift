//
//  MagicBorderView.swift
//  TestDrive
//

import SwiftUI
import Vortex

/// Sparkly particles flying outward across the whole screen, tinted with the chosen color.
///
/// The stock `.magic` preset emits along `.ring(radius: 0.5)`, producing a tight ring
/// in the centre. We swap the shape to a full-screen box so sparkles burst everywhere.
struct MagicBorderView: View {
    let color: Color

    @State private var system: VortexSystem = fullscreenMagic()

    // MARK: - Body

    var body: some View {
        VortexView(system) {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
                .blur(radius: 3)
                .tag("sparkle")
        }
        .ignoresSafeArea()
    }

    // MARK: - Private Helpers

    /// A unique copy of `.magic` reshaped to emit across the whole screen.
    private static func fullscreenMagic() -> VortexSystem {
        let system = VortexSystem.magic.makeUniqueCopy()
        system.shape = .box(width: 1, height: 1)
        return system
    }
}

#Preview {
    MagicBorderView(color: .purple)
        .frame(width: 800, height: 500)
        .background(.black)
}
