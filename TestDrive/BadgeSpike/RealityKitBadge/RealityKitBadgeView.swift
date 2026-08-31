//
//  RealityKitBadgeView.swift
//  TestDrive
//

import OSLog
import RealityKit
import SwiftUI

/// Approach 4 — real geometry in a `RealityView`, lit by a procedural environment.
///
/// The only approach here with an actual silhouette: spin it to 90° and you see the
/// rim. Reflections come from image-based lighting rather than being painted on, so
/// the highlight behaviour is a property of the scene instead of a gradient someone
/// tuned by hand.
///
/// Two independent rotations compose:
/// - the **medallion** turns with the drag, sweeping reflections across its faces
/// - the **lighting rig** turns with device tilt, sliding highlights while the badge
///   is still
///
/// Keeping them on separate entities is what makes both work at once. Put the
/// `ImageBasedLightComponent` on the badge itself and the environment travels with
/// it, which cancels the sweep and makes the reflections look like decals.
struct RealityKitBadgeView: View {
    private let badge: Badge
    private let angle: Double
    private let tilt: SIMD2<Double>

    @State private var loadFailure: String?

    // MARK: - Initializer

    /// Creates the badge.
    /// - Parameters:
    ///   - badge: The badge to render.
    ///   - angle: The spin angle, in degrees.
    ///   - tilt: Device tilt, which rotates the lighting rig.
    init(badge: Badge, angle: Double, tilt: SIMD2<Double>) {
        self.badge = badge
        self.angle = angle
        self.tilt = tilt
    }

    // MARK: - Body

    var body: some View {
        if let loadFailure {
            failureView(loadFailure)
        } else {
            realityView
        }
    }

    // MARK: - Private Views

    private var realityView: some View {
        RealityView { content in
            do {
                try await timed("RealityView build") { try await build(content) }
            } catch {
                badgeLog.error("build failed: \(error.localizedDescription, privacy: .public)")
                loadFailure = error.localizedDescription
            }
        } update: { content in
            apply(angle: angle, tilt: tilt, in: content)
        }
        // Rebuilt from scratch when the finish changes: the artwork is baked into a
        // texture, so a new badge means a new material. Fine on a detail screen,
        // and the `id` makes the teardown explicit rather than incidental.
        .id(badge.id)
    }

    /// Shown when the scene could not be assembled, rather than a blank rectangle.
    private func failureView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.orange)
        .padding()
    }

    // MARK: - Private Helpers

    /// Assembles the camera, the lighting rig and the medallion.
    private func build(_ content: RealityViewCameraContent) async throws {
        // A virtual camera, because there is no default worth relying on and the
        // framing needs to be deliberate: 1.78m back at 34° puts a 1m coin just
        // inside the frame with a little perspective on the rim. Matched by eye to
        // the flat tabs, so the comparison is not confounded by size.
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent(fieldOfViewInDegrees: 34))
        camera.look(at: .zero, from: [0, 0, 1.78], relativeTo: nil)
        content.add(camera)

        // The lighting rig. Holds the environment and nothing else, so it can be
        // rotated by tilt without moving the badge.
        let lightingRig = Entity()
        lightingRig.name = Self.lightingRigName

        let environment = try await timed("EnvironmentResource(equirectangular:)") {
            try await StudioEnvironment.makeResource()
        }

        var light = ImageBasedLightComponent(source: .single(environment))
        // The procedural panorama is SDR, so it carries nowhere near the dynamic
        // range of a real HDR capture. Lifting the exponent buys back some of the
        // punch a captured environment would have supplied for free.
        light.intensityExponent = 1.6
        // The rig's own rotation drives the environment — that is the whole reason
        // it is a separate entity.
        light.inheritsRotation = true
        lightingRig.components.set(light)
        content.add(lightingRig)

        // One directional light on top of the IBL. The environment alone lights the
        // metal beautifully but leaves the engraving's cut faces flat, because they
        // are the least reflective part of the face.
        let key = DirectionalLight()
        key.light.intensity = 4_200
        key.light.color = .white
        key.look(at: .zero, from: [0.6, 0.9, 1.4], relativeTo: nil)
        content.add(key)

        let medallion = try await timed("MedallionEntity.make") {
            try await MedallionEntity.make(badge: badge, lightingSource: lightingRig)
        }
        medallion.name = Self.medallionName
        content.add(medallion)
    }

    /// Pushes the current angle and tilt into the scene.
    private func apply(angle: Double, tilt: SIMD2<Double>, in content: RealityViewCameraContent) {
        if let medallion = content.entities.first(where: { $0.name == Self.medallionName }) {
            let yaw = simd_quatf(angle: Float(angle * .pi / 180), axis: [0, 1, 0])
            // A little counter-pitch from the device, so the coin leans toward the
            // viewer as the phone tips. Small: the badge should feel weighted, not loose.
            let pitch = simd_quatf(angle: Float(-tilt.y * 0.22), axis: [1, 0, 0])
            medallion.orientation = pitch * yaw
        }

        if let rig = content.entities.first(where: { $0.name == Self.lightingRigName }) {
            // Amplified well past the physical tilt. Rotating the environment 1:1 with
            // the phone barely moves a reflection; this is the gain that makes the
            // surface feel alive in the hand.
            rig.orientation = simd_quatf(angle: Float(tilt.x * 1.6), axis: [0, 0, 1])
                * simd_quatf(angle: Float(tilt.y * 1.2), axis: [1, 0, 0])
        }
    }

    private static let medallionName = "medallion-root"
    private static let lightingRigName = "lighting-rig"
}
