//
//  MedallionEntity.swift
//  TestDrive
//

import RealityKit
import SwiftUI
import UIKit

/// Builds a 3D medallion from the flat badge artwork — no USDZ required.
///
/// The trick this spike is testing: a thin cylinder supplies the rim and the
/// thickness, and two textured quads parked just outside its caps supply the faces.
/// `generateCylinder` is one material part with unknown cap UVs, so texturing its
/// end directly would stretch the art; `generatePlane` has clean UVs and a +z
/// normal, which is exactly what a badge face needs.
///
/// The payoff is that the asset cost drops to the same 2D art a flat approach
/// needs. No Blender, no Reality Composer Pro.
@MainActor
enum MedallionEntity {

    /// The medallion's radius, in metres. Everything else is derived from it so the
    /// proportions hold if the size changes.
    private static let radius: Float = 0.5

    /// How thick the coin is, as a fraction of the diameter.
    ///
    /// Dropped from 0.07 after the first render: at that depth the medallion read as
    /// a hockey puck rather than a struck medal. 0.03 against a 1.0 diameter is
    /// about a real coin's ratio, and the rim still catches a clear specular line
    /// when the badge turns — which is the whole reason for having thickness at all.
    private static let thickness: Float = 0.03

    // MARK: - Public Helpers

    /// Builds the medallion.
    /// - Parameters:
    ///   - badge: The badge whose artwork and finish to use.
    ///   - lightingSource: The entity carrying the ``ImageBasedLightComponent``.
    ///     Passed in rather than attached here so the badge can spin without
    ///     dragging its own reflections around with it.
    ///
    ///     Pass `nil` for a non-metallic medallion lit by ordinary scene lights,
    ///     which is what a typical textured USDZ behaves like — approach 5 uses this
    ///     to stand in for a real asset.
    /// - Returns: An entity containing the rim and both faces.
    static func make(badge: Badge, lightingSource: Entity?) async throws -> Entity {
        let medallion = Entity()
        medallion.name = "medallion"

        let isMetallic = lightingSource != nil

        let rim = makeRim(badge: badge, isMetallic: isMetallic)
        medallion.addChild(rim)

        // 1024 rather than the 512 default: the reverse is mostly small engraved
        // text, and at 512 it turns to mush once the quad is viewed at an angle.
        let faceTexture = try await makeTexture(named: "face") {
            BadgeFaceView.renderedFace(for: badge, size: 1024)
        }
        let backTexture = try await makeTexture(named: "back") {
            BadgeBackView.renderedBack(for: badge, size: 1024)
        }

        // Front and back, offset a hair beyond the cylinder cap so they never
        // z-fight with it.
        let offset = thickness / 2 + 0.001

        let front = makeFace(texture: faceTexture, badge: badge, isMetallic: isMetallic)
        front.position = [0, 0, offset]
        medallion.addChild(front)

        let back = makeFace(texture: backTexture, badge: badge, isMetallic: isMetallic)
        back.position = [0, 0, -offset]
        // Turned to face away, so the reverse is not a mirror image of the front.
        back.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        medallion.addChild(back)

        // Every part reflects the shared environment, when there is one.
        if let lightingSource {
            for entity in [rim, front, back] {
                entity.components.set(
                    ImageBasedLightReceiverComponent(imageBasedLight: lightingSource)
                )
            }
        }

        return medallion
    }

    // MARK: - Private Helpers

    /// The coin's body: a cylinder turned to lie flat, facing the camera.
    ///
    /// `generateCylinder` centres the mesh on the origin with its axis along **y**,
    /// so it stands up like a drum. Rotating -90° about x lays it down with its caps
    /// pointing along z, which is where the camera is.
    private static func makeRim(badge: Badge, isMetallic: Bool) -> ModelEntity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(badge.finish.rimColor))
        material.metallic = .init(floatLiteral: isMetallic ? 1.0 : 0.0)
        // Slightly glossier than the faces: a machined edge is the shiniest part of a
        // real coin, and it gives the silhouette a bright outline as it turns.
        material.roughness = .init(
            floatLiteral: isMetallic ? max(badge.finish.roughness - 0.08, 0.05) : 0.45
        )

        let rim = ModelEntity(
            mesh: .generateCylinder(height: thickness, radius: radius),
            materials: [material]
        )
        rim.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        return rim
    }

    /// One textured face.
    private static func makeFace(
        texture: TextureResource,
        badge: Badge,
        isMetallic: Bool
    ) -> ModelEntity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(texture))
        // Not fully metallic. At 1.0 the dark engraving reflects the environment as
        // much as the bright metal does and the detail disappears; backing off keeps
        // the cut legible while the surround still behaves like gold.
        material.metallic = .init(floatLiteral: isMetallic ? 0.85 : 0.0)
        material.roughness = .init(floatLiteral: isMetallic ? badge.finish.roughness : 0.5)

        // Inset slightly so the rim reads as a raised lip around the art.
        let diameter = (radius - 0.015) * 2

        return ModelEntity(
            mesh: .generatePlane(width: diameter, height: diameter, cornerRadius: diameter / 2),
            materials: [material]
        )
    }

    /// Rasterizes a SwiftUI badge side into a texture.
    /// - Parameters:
    ///   - name: A label for the timing log.
    ///   - render: Produces the artwork.
    /// - Returns: The texture.
    private static func makeTexture(
        named name: String,
        render: @MainActor () -> CGImage?
    ) async throws -> TextureResource {
        guard let image = await timed("ImageRenderer \(name)", { render() }) else {
            throw MedallionError.artworkRenderFailed
        }

        return try await timed("TextureResource \(name)") {
            try await TextureResource(image: image, options: .init(semantic: .color))
        }
    }
}
