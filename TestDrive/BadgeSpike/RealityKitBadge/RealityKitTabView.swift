//
//  RealityKitTabView.swift
//  TestDrive
//

import SwiftUI

/// Hosts approach 4.
struct RealityKitTabView: View {
    @State private var selection = Badge.samples[0]
    @State private var spin = SpinGesture()
    @State private var motion = BadgeMotion()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        BadgeStage(selection: $selection, notes: Self.notes) { badge in
            RealityKitBadgeView(
                badge: badge,
                angle: spin.angle,
                tilt: motion.tilt
            )
            .gesture(dragGesture)
            .idleDrift(spin: spin, isEnabled: isDriftEnabled)
            .onAppear { motion.start(reduceMotion: reduceMotion) }
            .onDisappear { motion.stop() }
        }
    }

    // MARK: - Private Views

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { spin.drag(translation: $0.translation.width) }
            .onEnded { spin.endDrag(predictedTranslation: $0.predictedEndTranslation.width) }
    }

    // MARK: - Private Helpers

    private var isDriftEnabled: Bool {
        !motion.isAvailable && !reduceMotion && !CaptureOverrides.isFrozen
    }

    private static let notes = [
        "Real geometry: a generated cylinder for the rim, two textured quads for the faces.",
        "No USDZ — the 3D model is built from the same 2D art the flat tabs use.",
        "Lit by a procedurally drawn equirectangular environment, so the metal reflects something.",
        "Spin to 90°: unlike tabs 1–3, there is an actual edge there.",
        "One renderer per screen. Do not put this in a grid cell."
    ]
}

#Preview {
    RealityKitTabView()
}
