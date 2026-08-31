//
//  ArtworkExporter.swift
//  TestDrive
//

import OSLog
import SwiftUI
import UniformTypeIdentifiers

/// Writes the badge artwork to PNG files, for baking into a USDZ.
///
/// The medallion USDZ that approach 5 loads has to be textured with the *same*
/// artwork the other tabs draw, or the comparison is measuring two different
/// designs. Rather than redrawing the badge in another tool, the SwiftUI views are
/// rasterized here and the PNGs are packaged into the USDZ offline — so the asset
/// and the live views can never drift apart.
///
/// DEBUG-only, and driven by a launch argument rather than any UI:
/// ```
/// xcrun simctl launch <device> com.rspoon3.TestDrive -exportBadgeArtwork 1
/// xcrun simctl get_app_container <device> com.rspoon3.TestDrive data
/// ```
/// Then `Tools/make-badge-usdz.py` turns them into `badge_medallion.usdz`.
enum ArtworkExporter {

    // MARK: - Public Helpers

    /// Whether a launch argument asked for an export.
    static var isRequested: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "exportBadgeArtwork")
        #else
        false
        #endif
    }

    /// Writes a face and reverse PNG per sample badge into the Documents directory.
    ///
    /// 1024px because the reverse is mostly small engraved text, which does not
    /// survive being mapped onto a quad at 512.
    @MainActor
    static func exportAll() {
        guard
            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else {
            badgeLog.error("no documents directory to export into")
            return
        }

        for badge in Badge.samples {
            let slug = badge.finish.rawValue

            write(BadgeFaceView.renderedFace(for: badge, size: 1024), to: documents, named: "\(slug)-face")
            write(BadgeBackView.renderedBack(for: badge, size: 1024), to: documents, named: "\(slug)-back")
        }

        badgeLog.info("artwork exported to \(documents.path, privacy: .public)")
    }

    // MARK: - Private Helpers

    /// Writes one image as a PNG.
    private static func write(_ image: CGImage?, to directory: URL, named name: String) {
        guard let image else {
            badgeLog.error("could not render \(name, privacy: .public)")
            return
        }

        let url = directory.appending(path: "\(name).png")

        guard
            let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else {
            badgeLog.error("could not create destination for \(name, privacy: .public)")
            return
        }

        CGImageDestinationAddImage(destination, image, nil)

        if CGImageDestinationFinalize(destination) {
            badgeLog.info("wrote \(name, privacy: .public).png")
        } else {
            badgeLog.error("failed writing \(name, privacy: .public).png")
        }
    }
}
