//
//  ArticleARViewTabView.swift
//  TestDrive
//

import SwiftUI

/// Hosts approach 5, with a picker for which model to load.
struct ArticleARViewTabView: View {
    @State private var selection = Badge.samples[3]
    @State private var source = BadgeModelSource.baseball

    // MARK: - Body

    var body: some View {
        BadgeStage(selection: $selection, notes: Self.notes) { badge in
            VStack(spacing: 12) {
                ArticleBadgeARView(badge: badge, source: source)
                    // Rebuilt when either input changes: the coordinator loads once,
                    // and the procedural fallback bakes artwork into a texture.
                    .id("\(badge.id)-\(source.rawValue)")

                sourcePicker
            }
        }
    }

    // MARK: - Private Views

    /// Switches between the USDZ models and the procedural stand-in.
    private var sourcePicker: some View {
        Picker("Model", selection: $source) {
            ForEach(BadgeModelSource.allCases) { source in
                Text(source.title).tag(source)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 8)
    }

    // MARK: - Private Helpers

    private static let notes = [
        "The Medium article's approach: ARView(.nonAR) in a UIViewRepresentable.",
        "Teapot and Baseball are Apple AR Quick Look samples — no free medal USDZ was downloadable without an account, so they stand in to exercise the real ModelEntity(named:) path.",
        "'rozet (missing)' is the article's own asset name: it is not here, so you see the fallback path.",
        "9-10MB per USDZ, against the article's own 1-5MB advice. Five badges is 50MB of app.",
        "No image-based lighting, so the surface is duller than approach 4's.",
        "Pan is clamped to ±90°, so the reverse never comes round — no earned date visible here.",
        "The gesture lives in a UIKit coordinator, so SwiftUI state cannot drive it."
    ]
}

#Preview {
    ArticleARViewTabView()
}
