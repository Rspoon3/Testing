//
//  BadgeModelSource.swift
//  TestDrive
//

import Foundation
import simd

/// What approach 5 loads into its `ARView`.
///
/// The article's own `rozet.usdz` is not publicly available, Apple's AR Quick Look
/// gallery has no medal, and every free medal USDZ found needed an account. So
/// `badgeMedallion` is *generated*: `Tools/make-badge-usdz.py` wraps the artwork
/// exported by ``ArtworkExporter`` around authored USD geometry. That keeps the USDZ
/// and the live SwiftUI views showing the same design, which is the only way the
/// comparison against approach 4 means anything.
enum BadgeModelSource: String, CaseIterable, Identifiable {
    /// The generated badge medallion — a real USDZ, loaded the article's way.
    case badgeMedallion

    /// The article's own asset name. Absent from this repo, so selecting it shows
    /// what the article's code does when its model is missing.
    case rozet

    /// The procedural medallion the other tabs build at runtime, with a
    /// non-metallic material.
    case procedural

    var id: String { rawValue }

    /// The bundle resource name, or `nil` to build the medallion at runtime instead.
    var modelName: String? {
        switch self {
        case .badgeMedallion: "badge_medallion"
        case .rozet: "rozet"
        case .procedural: nil
        }
    }

    /// The picker's label.
    var title: String {
        switch self {
        case .badgeMedallion: "Badge USDZ"
        case .rozet: "rozet (missing)"
        case .procedural: "Procedural"
        }
    }

    /// A correction applied before anything else, to face the model at the camera.
    ///
    /// The article hard-codes a -90° yaw because *its* export faces the wrong way.
    /// That is a property of one asset, not of the technique — the generated
    /// medallion is authored facing +z and needs none. Getting this wrong turns the
    /// badge edge-on, so it belongs beside the asset rather than in the loader.
    var yawCorrection: simd_quatf {
        switch self {
        case .rozet: simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(0, 1, 0))
        case .badgeMedallion, .procedural: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        }
    }

    /// The edge length, in metres, every model is fitted to.
    ///
    /// Replaces the article's per-asset `scale *= 1.6`. Assets are authored at wildly
    /// different real-world sizes, so a fixed multiplier has to be retuned for each
    /// one — guessing it was how a test model ended up first invisible and then
    /// cropped out of frame. Measuring the model's own bounds and normalizing means
    /// any USDZ dropped in frames correctly. See
    /// `ArticleBadgeARView.Coordinator.fit(_:in:)`.
    static let targetSize: Float = 2.1
}
