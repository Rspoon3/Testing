//
//  BadgeModelSource.swift
//  TestDrive
//

import Foundation

/// What approach 5 loads into its `ARView`.
///
/// Apple's AR Quick Look gallery has no medal or badge, and every free medal USDZ
/// found needed an account to download — so these are stand-ins whose job is to
/// exercise the article's real `ModelEntity(named:)` path with authored PBR
/// materials, not to look like a badge. Swap in real artwork by dropping a USDZ
/// beside these and adding a case.
enum BadgeModelSource: String, CaseIterable, Identifiable {
    /// The article's own asset name. Absent from this repo — selecting it shows what
    /// the article's code does when the model is missing.
    case rozet

    /// Apple's teapot. Deliberately obviously a placeholder, and a good test of
    /// authored materials since it is the classic shiny reference object.
    case teapot

    /// Apple's baseball. Round, so it frames like a badge.
    case baseball

    /// The procedural medallion the other tabs use, with a non-metallic material.
    case procedural

    var id: String { rawValue }

    /// The bundle resource name, or `nil` to build the medallion instead.
    var modelName: String? {
        switch self {
        case .rozet: "rozet"
        case .teapot: "teapot"
        case .baseball: "ball_baseball_realistic"
        case .procedural: nil
        }
    }

    /// The picker's label.
    var title: String {
        switch self {
        case .rozet: "rozet (missing)"
        case .teapot: "Teapot"
        case .baseball: "Baseball"
        case .procedural: "Procedural"
        }
    }

    /// The edge length, in metres, every model is fitted to.
    ///
    /// Replaces the article's per-asset `scale *= 1.6` magic number. Assets are
    /// authored at wildly different real-world sizes — the teapot is centimetres, the
    /// baseball is centimetres, the procedural medallion is a metre — so a fixed
    /// multiplier has to be retuned for each one, and guessing it was how the baseball
    /// ended up first invisible and then cropped out of frame.
    ///
    /// Measuring the model's own bounds and normalizing is strictly better: any USDZ
    /// dropped in frames correctly with no tuning. See
    /// `ArticleBadgeARView.Coordinator.fit(_:)`.
    static let targetSize: Float = 2.1
}
