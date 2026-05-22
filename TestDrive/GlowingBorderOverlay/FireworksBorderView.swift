//
//  FireworksBorderView.swift
//  TestDrive
//

import AppKit
import SwiftUI
import Vortex

/// Fireworks launching from random spots along the bottom edge and exploding overhead.
///
/// Vortex's stock `.fireworks` preset launches from a single point `[0.5, 1]`,
/// so we widen the launch shape to a full-width strip. The secondary explosion
/// system's `colors` is also overridden so the user-facing ``FireworksColorMode``
/// drives the look:
///
/// * `.fixed` — explosions use the supplied `color` via a white→color ramp.
/// * `.multicolor` — each particle picks a random color from a wide palette.
/// * `.random` — each firework lands on one solid color, with the active color
///   cycled by a background `Task` between launches so successive fireworks differ.
///
/// The library's docs require the `"circle"` tag use `.blendMode(.plusLighter)`.
struct FireworksBorderView: View {
    let colorMode: FireworksColorMode
    let color: Color

    @State private var system: VortexSystem

    /// Palette used by `.random` (per-firework) and `.multicolor` (per-particle).
    private static let palette: [VortexSystem.Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan
    ]

    // MARK: - Initializer

    init(colorMode: FireworksColorMode, color: Color) {
        self.colorMode = colorMode
        self.color = color
        _system = State(initialValue: Self.fullScreenFireworks(colorMode: colorMode, color: color))
    }

    // MARK: - Body

    var body: some View {
        VortexView(system) {
            Circle()
                .fill(.white)
                .frame(width: 32, height: 32)
                .blendMode(.plusLighter)
                .tag("circle")
        }
        .ignoresSafeArea()
        .task(id: colorMode) { await cycleRandomColorIfNeeded() }
    }

    // MARK: - Private Helpers

    /// When `colorMode == .random`, periodically rotates the explosion system's
    /// `colors` to a new solid color. Each new firework's death calls
    /// `secondarySystem.makeUniqueCopy()`, which captures whatever value was set
    /// most recently — so successive fireworks pick up different colors.
    private func cycleRandomColorIfNeeded() async {
        guard colorMode == .random else { return }
        while !Task.isCancelled {
            guard let pick = Self.palette.randomElement() else { return }
            for secondary in system.secondarySystems where secondary.spawnOccasion == .onDeath {
                secondary.colors = .single(pick)
            }
            try? await Task.sleep(for: .milliseconds(400))
        }
    }

    /// Builds a unique copy of the `.fireworks` preset whose launches span the
    /// full bottom edge and whose explosion `colors` reflect the initial mode.
    private static func fullScreenFireworks(colorMode: FireworksColorMode, color: Color) -> VortexSystem {
        let main = VortexSystem.fireworks.makeUniqueCopy()
        // Spread launches across the entire bottom edge instead of a single point.
        main.shape = .box(width: 1, height: 0)
        main.position = [0.5, 1]

        // makeUniqueCopy only shallow-copies the secondary systems, so we have to
        // unique-copy each one before mutating to avoid clobbering the shared
        // static preset other parts of the app might rely on.
        main.secondarySystems = main.secondarySystems.map { $0.makeUniqueCopy() }
        for secondary in main.secondarySystems where secondary.spawnOccasion == .onDeath {
            secondary.colors = colors(for: colorMode, color: color)
        }

        return main
    }

    /// Returns the Vortex `ColorMode` matching `mode`. The `.random` case
    /// returns a placeholder; the running view rotates it via a background `Task`.
    private static func colors(for mode: FireworksColorMode, color: Color) -> VortexSystem.ColorMode {
        switch mode {
        case .fixed:
            // White-to-color fade matches the look of the preset's white-to-X ramps.
            let vortexColor = VortexSystem.Color(swiftUI: color)
            return .ramp([.white, vortexColor, vortexColor])
        case .multicolor:
            // Each particle picks one solid color from the palette (no white flash).
            return .random(palette)
        case .random:
            // Replaced at runtime by `cycleRandomColorIfNeeded`.
            return .single(palette.first ?? .red)
        }
    }
}

#Preview("Fixed") {
    FireworksBorderView(colorMode: .fixed, color: .red)
        .frame(width: 800, height: 500)
        .background(.black)
}

#Preview("Multi-color") {
    FireworksBorderView(colorMode: .multicolor, color: .red)
        .frame(width: 800, height: 500)
        .background(.black)
}

#Preview("Random") {
    FireworksBorderView(colorMode: .random, color: .red)
        .frame(width: 800, height: 500)
        .background(.black)
}
