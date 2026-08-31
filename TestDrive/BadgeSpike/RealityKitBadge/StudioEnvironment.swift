//
//  StudioEnvironment.swift
//  TestDrive
//

import CoreGraphics
import Foundation
import RealityKit
import UIKit

/// Builds the image-based lighting the metal reflects.
///
/// This is the single biggest contributor to whether the badge reads as gold or as
/// a yellow gradient: a metallic PBR material with nothing to reflect renders
/// black. Rather than shipping an HDR panorama, the environment is drawn at
/// runtime — a dark floor, a bright sky, and two soft-boxes — which is enough
/// structure for highlights to sweep across as the medallion turns and costs no
/// asset.
enum StudioEnvironment {

    // MARK: - Public Helpers

    /// Creates the lighting resource.
    /// - Returns: An environment built from a procedurally drawn panorama.
    @MainActor
    static func makeResource() async throws -> EnvironmentResource {
        try await EnvironmentResource(equirectangular: makePanorama())
    }

    /// Draws the equirectangular panorama.
    ///
    /// RealityKit wants a 2:1 latitude-longitude image: width is a 360° sweep along
    /// the horizon, height runs from -90° at the bottom to +90° at the top.
    /// - Returns: The panorama image.
    static func makePanorama() -> CGImage {
        let width = 1024
        let height = 512
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        drawSkyAndFloor(in: context, width: width, height: height, colorSpace: colorSpace)
        drawSoftBoxes(in: context, width: width, height: height, colorSpace: colorSpace)

        return context.makeImage()!
    }

    // MARK: - Private Helpers

    /// The vertical gradient: bright above the horizon, dark below it.
    ///
    /// The hard-ish transition at the halfway line is deliberate. A smooth
    /// top-to-bottom fade gives metal nothing to catch, where a horizon produces the
    /// bright band across the middle of a coin that makes it look polished.
    private static func drawSkyAndFloor(
        in context: CGContext,
        width: Int,
        height: Int,
        colorSpace: CGColorSpace
    ) {
        let stops: [CGFloat] = [0, 0.42, 0.5, 0.58, 1]
        // Brightened substantially after the first render came back a dim olive.
        // A metallic face reflects the environment rather than being lit by it, so
        // "too dark" is not a lighting bug to fix with more lights — the panorama
        // itself has to be bright enough to be worth reflecting.
        let components: [CGFloat] = [
            0.06, 0.06, 0.08, 1,   // straight down — near black
            0.28, 0.28, 0.32, 1,
            0.95, 0.95, 0.98, 1,   // the horizon band
            1.00, 1.00, 1.00, 1,
            0.62, 0.68, 0.82, 1    // straight up — cool and dimmer than the horizon
        ]

        let gradient = CGGradient(
            colorSpace: colorSpace,
            colorComponents: components,
            locations: stops,
            count: stops.count
        )!

        context.drawLinearGradient(
            gradient,
            start: .init(x: 0, y: 0),
            end: .init(x: 0, y: CGFloat(height)),
            options: []
        )
    }

    /// Two bright soft-boxes and one warm bounce.
    ///
    /// Placed off-center and at different sizes so the two faces of the medallion
    /// never catch identical highlights, which is what would give away that the
    /// reflection is painted on.
    private static func drawSoftBoxes(
        in context: CGContext,
        width: Int,
        height: Int,
        colorSpace: CGColorSpace
    ) {
        // x = 0 is the +z direction, which is where the camera sits — so the two
        // wrapping soft-boxes at the image's left and right edges are what a
        // face-on medallion reflects. Without them the badge is dark at 0° and only
        // lights up once it turns, which is exactly what the first render did.
        let lights: [(x: CGFloat, y: CGFloat, radius: CGFloat, color: [CGFloat])] = [
            (0.00, 0.62, 0.30, [1.0, 1.0, 1.0, 1]),
            (1.00, 0.62, 0.30, [1.0, 1.0, 1.0, 1]),
            (0.26, 0.70, 0.15, [1.0, 1.0, 1.0, 1]),
            (0.72, 0.60, 0.12, [0.95, 0.97, 1.0, 1]),
            (0.48, 0.36, 0.20, [1.0, 0.78, 0.50, 1])
        ]

        for light in lights {
            let components = light.color + [light.color[0], light.color[1], light.color[2], 0]
            let gradient = CGGradient(
                colorSpace: colorSpace,
                colorComponents: components,
                locations: [0, 1],
                count: 2
            )!

            let center = CGPoint(
                x: light.x * CGFloat(width),
                y: light.y * CGFloat(height)
            )

            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: light.radius * CGFloat(width),
                options: []
            )
        }
    }
}
