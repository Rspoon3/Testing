//
//  ArticleBadgeARView.swift
//  TestDrive
//

import ARKit
import OSLog
import RealityKit
import SwiftUI

/// Approach 5 — the Medium article's structure, implemented as written.
///
/// `ARView` in `.nonAR` mode wrapped in `UIViewRepresentable`, a USDZ loaded with
/// `ModelEntity.loadModel(named:)`, and a `UIPanGestureRecognizer` whose yaw is
/// clamped to ±90°. No image-based lighting, no device motion, no shaders — the
/// article does not use them, and keeping it faithful is the point: this tab exists
/// to be compared against approach 4, which adds exactly those things.
///
/// Two deliberate deviations, both flagged in the tab's notes:
/// - **No `rozet.usdz` in this repo.** The article's asset is not public, so
///   `badge_medallion.usdz` is generated instead — see `Tools/make-badge-usdz.py`.
///   It wraps the same artwork the other tabs draw around authored USD geometry, so
///   this tab loads a real badge through the real `ModelEntity(named:)` path rather
///   than displaying a stand-in object.
/// - `ARView` is legacy surface for new code on iOS 26; `RealityView` in approach 4
///   is the supported path. Included because it is what the article specifies.
struct ArticleBadgeARView: UIViewRepresentable {
    /// The badge to render, used only by the procedural fallback.
    let badge: Badge

    /// Which model to load.
    let source: BadgeModelSource

    // MARK: - Public Helpers

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        // The article's initializer, verbatim: a fully virtual scene with no session
        // configuration, so nothing touches the device camera.
        let arView = ARView(
            frame: .zero,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        arView.environment.background = .color(.clear)
        arView.backgroundColor = .clear

        let anchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(anchor)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(pan)

        Task { @MainActor in
            let entity = await context.coordinator.loadBadge(source: source, badge: badge)
            anchor.addChild(entity)
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Nothing to push: this approach's only input is its own pan recognizer.
        // That is the difference from approach 4, which is driven by SwiftUI state.
    }
}

extension ArticleBadgeARView {

    /// Owns the loaded entity and the clamped yaw.
    @MainActor
    final class Coordinator: NSObject {
        private var entity: Entity?
        private var baseRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
        private var currentYaw: Float = 0

        // MARK: - Public Helpers

        /// Loads the requested USDZ, falling back to the procedural medallion.
        ///
        /// Returns a container entity whose single child is the fitted model. The
        /// split matters: the child carries the centring offset and the fit scale,
        /// the container carries only the gesture's rotation. Rotating a model whose
        /// own transform also holds a centring offset makes it orbit the origin
        /// instead of spinning in place.
        /// - Parameters:
        ///   - source: Which model to load.
        ///   - badge: The badge for the procedural stand-in.
        /// - Returns: The container to anchor.
        func loadBadge(source: BadgeModelSource, badge: Badge) async -> Entity {
            let model: Entity

            if
                let name = source.modelName,
                let loaded = try? await ModelEntity(named: name)
            {
                // The article's axis correction, but per-asset — see
                // `BadgeModelSource.yawCorrection` for why it cannot be a constant.
                loaded.transform.rotation = simd_mul(
                    source.yawCorrection,
                    loaded.transform.rotation
                )
                model = loaded
            } else {
                if let name = source.modelName {
                    badgeLog.error(
                        "USDZ '\(name, privacy: .public)' not in bundle — using the procedural medallion"
                    )
                }
                model = (try? await MedallionEntity.make(badge: badge, lightingSource: nil))
                    ?? Entity()
            }

            let container = Entity()
            container.addChild(model)
            fit(model, in: container)

            entity = container
            baseRotation = container.transform.rotation
            return container
        }

        /// Centres a model on its container's origin and scales it to fill the frame.
        ///
        /// Replaces the article's per-asset `scale *= 1.6`: measuring the model's own
        /// bounds means any USDZ dropped in frames correctly without a hand-tuned
        /// number per file.
        /// - Parameters:
        ///   - model: The model to fit, mutated in place.
        ///   - container: The parent the bounds are measured against.
        private func fit(_ model: Entity, in container: Entity) {
            let bounds = model.visualBounds(relativeTo: container)
            let extent = bounds.extents.max()
            guard extent > 0 else { return }

            let scale = BadgeModelSource.targetSize / extent
            model.scale *= SIMD3<Float>(repeating: scale)
            // Applied after scaling, and in the parent's space, so it has to be
            // scaled too — this is the step that was applied twice before.
            model.position = -bounds.center * scale
        }

        /// Turns the badge with a one-finger drag, clamped to ±90°.
        ///
        /// The clamp is the article's choice and worth feeling directly: it stops the
        /// badge before the edge comes round, which conveniently hides that a
        /// single-sided model has nothing on the back.
        @objc
        func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let entity else { return }

            let translation = recognizer.translation(in: recognizer.view)
            let deltaYaw = Float(translation.x) * 0.01
            currentYaw = min(max(currentYaw + deltaYaw, -.pi / 2), .pi / 2)

            let yawQuat = simd_quatf(angle: currentYaw, axis: [0, 1, 0])
            entity.transform.rotation = simd_mul(yawQuat, baseRotation)

            // Reset each frame so `translation.x` is a per-frame delta rather than a
            // cumulative one. Without this the badge accelerates to the clamp
            // instantly, which is a bug the article's snippet does not address.
            recognizer.setTranslation(.zero, in: recognizer.view)
        }
    }
}
