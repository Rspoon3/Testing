//
//  ShaderTabView.swift
//  TestDrive
//

import SwiftUI

/// Hosts approach 3.
struct ShaderTabView: View {
    @State private var selection = Badge.samples[2]
    @State private var spin = SpinGesture()
    @State private var motion = BadgeMotion()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        BadgeStage(selection: $selection, notes: Self.notes) { badge in
            ShaderBadgeView(
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
        "A stitchable Metal layerEffect faking image-based lighting in screen space.",
        "Tilt the device: the highlight slides across the machined face.",
        "Grid-safe — it is one fragment pass over an already-rasterized layer.",
        "No real geometry, so like 1 and 2 the silhouette never changes."
    ]
}

#Preview {
    ShaderTabView()
}
