//
//  BadgeFaceView.swift
//  TestDrive
//

import SwiftUI

/// The flat medallion artwork every tab renders.
///
/// Deliberately drawn in SwiftUI rather than shipped as a PNG, because the
/// RealityKit tabs need it as a `CGImage` texture too — see
/// ``renderedFace(for:size:)``. One source of art means the five approaches are
/// compared on identical pixels.
struct BadgeFaceView: View {
    private let badge: Badge

    // MARK: - Initializer

    /// Creates the badge face.
    /// - Parameter badge: The badge to draw.
    init(badge: Badge) {
        self.badge = badge
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            metalDisc
            engravedRing
            engraving
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Private Views

    /// The struck metal blank.
    private var metalDisc: some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: badge.finish.faceColors + badge.finish.faceColors.reversed(),
                    center: .center
                )
            )
            .overlay {
                // A radial darkening toward the rim, so the disc reads as domed
                // rather than as a flat gradient.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.35), .clear, .black.opacity(0.45)],
                            center: .init(x: 0.35, y: 0.3),
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
            }
    }

    /// The raised ring just inside the rim.
    private var engravedRing: some View {
        Circle()
            .strokeBorder(badge.finish.engravingColor.opacity(0.55), lineWidth: 3)
            .padding(14)
    }

    /// The symbol and count cut into the face.
    private var engraving: some View {
        VStack(spacing: 2) {
            Image(systemName: badge.symbolName)
                .font(.system(size: 74, weight: .semibold))
                .foregroundStyle(badge.finish.engravingColor)
                // A one-pixel light offset under the glyph fakes a bevelled cut.
                .shadow(color: .white.opacity(0.5), radius: 0, y: 1.5)

            Text(badge.formattedCount)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(badge.finish.engravingColor)
                .shadow(color: .white.opacity(0.5), radius: 0, y: 1)
        }
    }
}

extension BadgeFaceView {

    // MARK: - Public Helpers

    /// Rasterizes the face for use as a RealityKit texture.
    ///
    /// `ImageRenderer` is `@MainActor`, and both RealityKit tabs need the result
    /// before they can build a material, so this is the bridge between the SwiftUI
    /// artwork and the 3D medallion.
    /// - Parameters:
    ///   - badge: The badge to draw.
    ///   - size: The texture's pixel size. Powers of two keep RealityKit's
    ///     mipmapping happy.
    /// - Returns: The rendered face, or `nil` if rasterization failed.
    @MainActor
    static func renderedFace(for badge: Badge, size: CGFloat = 512) -> CGImage? {
        let renderer = ImageRenderer(
            content: BadgeFaceView(badge: badge)
                .badgeCanvas(scaledTo: size)
                // Opaque black behind the disc: the texture is applied to a quad, and
                // a transparent surround would need alpha blending set up on the
                // material for no visual gain at this size.
                .background(.black)
        )
        renderer.scale = 1
        return renderer.cgImage
    }
}

#Preview {
    VStack(spacing: 24) {
        ForEach(Badge.samples) { badge in
            BadgeFaceView(badge: badge)
                .frame(width: 150)
        }
    }
    .padding()
}
