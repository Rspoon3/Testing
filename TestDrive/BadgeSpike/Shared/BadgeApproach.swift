//
//  BadgeApproach.swift
//  TestDrive
//

import Foundation

/// The five rendering approaches under comparison, one per tab.
enum BadgeApproach: Hashable {
    /// Pure SwiftUI: `rotation3DEffect` and a gradient sheen.
    case flat

    /// iOS 26 Liquid Glass layered over flat artwork.
    case glass

    /// A Metal `layerEffect` faking image-based lighting in screen space.
    case shader

    /// Real geometry in a `RealityView`, lit by a procedural environment.
    case realityView

    /// The Medium article's `ARView(.nonAR)` + `UIViewRepresentable` structure.
    case articleARView
}

extension BadgeApproach {

    // MARK: - Public Helpers

    /// The tab named by a `-badgeTab <case>` launch argument, if any.
    ///
    /// Exists so each approach can be launched and captured in isolation from the
    /// command line, which is how this spike was evaluated. Debug-only: a launch
    /// argument that changes the first screen has no business in a shipping build.
    static var launchOverride: BadgeApproach? {
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "badgeTab") {
        case "flat": .flat
        case "glass": .glass
        case "shader": .shader
        case "realityView": .realityView
        case "articleARView": .articleARView
        default: nil
        }
        #else
        nil
        #endif
    }
}
