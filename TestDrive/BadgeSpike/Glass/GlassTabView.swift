//
//  GlassTabView.swift
//  TestDrive
//

import SwiftUI

/// Hosts approach 2.
struct GlassTabView: View {
    @State private var selection = Badge.samples[1]
    @State private var spin = SpinGesture()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        BadgeStage(selection: $selection, notes: Self.notes) { badge in
            GlassBadgeView(badge: badge, angle: spin.angle)
                .gesture(dragGesture)
                .idleDrift(spin: spin, isEnabled: !reduceMotion && !CaptureOverrides.isFrozen)
        }
    }

    // MARK: - Private Views

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { spin.drag(translation: $0.translation.width) }
            .onEnded { spin.endDrag(predictedTranslation: $0.predictedEndTranslation.width) }
    }

    // MARK: - Private Helpers

    private static let notes = [
        "Liquid Glass layered over the same flat artwork. Zero custom rendering.",
        "The specular and edge refraction come from the system material for free.",
        "Glass is tuned to look like glass, not struck metal — judge whether that reads as a medallion.",
        "Still fundamentally flat: the spin has the same ~60° ceiling as approach 1."
    ]
}

#Preview {
    GlassTabView()
}
