//
//  ContentView.swift
//  TestDrive
//

import SwiftUI

/// Five ways to render an Apple Fitness-style 3D badge, one per tab, on identical
/// artwork so only the technique differs.
///
/// 1. **Flat** — `rotation3DEffect` plus a masked gradient sheen.
/// 2. **Glass** — iOS 26 Liquid Glass over the same art.
/// 3. **Shader** — a Metal `layerEffect` faking image-based lighting.
/// 4. **RealityView** — real geometry, procedural environment lighting, gyro.
/// 5. **ARView** — the Medium article's `UIViewRepresentable` + USDZ structure.
struct ContentView: View {
    @State private var selectedTab: BadgeApproach = BadgeApproach.launchOverride ?? .flat

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Flat", systemImage: "circle.dashed", value: BadgeApproach.flat) {
                FakeThreeDTabView()
            }

            Tab("Glass", systemImage: "drop.fill", value: BadgeApproach.glass) {
                GlassTabView()
            }

            Tab("Shader", systemImage: "sparkles", value: BadgeApproach.shader) {
                ShaderTabView()
            }

            Tab("RealityView", systemImage: "cube.fill", value: BadgeApproach.realityView) {
                RealityKitTabView()
            }

            Tab("ARView", systemImage: "arkit", value: BadgeApproach.articleARView) {
                ArticleARViewTabView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
