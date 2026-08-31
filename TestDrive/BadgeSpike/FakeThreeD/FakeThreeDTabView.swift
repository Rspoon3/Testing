//
//  FakeThreeDTabView.swift
//  TestDrive
//

import SwiftUI

/// Hosts approach 1 and drives its spin.
struct FakeThreeDTabView: View {
    @State private var selection = Badge.samples[0]
    @State private var spin = SpinGesture()
    @State private var motion = BadgeMotion()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        BadgeStage(selection: $selection, notes: Self.notes) { badge in
            FakeThreeDBadgeView(
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

    /// Drag to spin, release to fling.
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { spin.drag(translation: $0.translation.width) }
            .onEnded { spin.endDrag(predictedTranslation: $0.predictedEndTranslation.width) }
    }

    // MARK: - Private Helpers

    /// Drift only where the device cannot supply tilt, so on a real phone the badge
    /// responds to the hand rather than spinning on its own.
    private var isDriftEnabled: Bool {
        !motion.isAvailable && !reduceMotion && !CaptureOverrides.isFrozen
    }

    private static let notes = [
        "rotation3DEffect + a masked gradient sheen. No 3D framework, no assets.",
        "Cheap enough for a scrolling grid — this is what a badge list should use.",
        "Breaks down past ~60°: there is no edge to show, so the disc reads as a card.",
        "The back face is a separate view swapped at 90°, not real geometry."
    ]
}

#Preview {
    FakeThreeDTabView()
}
