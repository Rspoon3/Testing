//
//  TestDriveApp.swift
//  TestDrive
//
//  Bouncing balls desktop overlay (macOS).
//
//  A single-file SwiftUI + SceneKit app that paints physics-driven 3D balls
//  onto a transparent, click-through window covering the screen. Everything
//  needed for the effect lives in this file.
//

import SwiftUI
import SceneKit
import AppKit

// MARK: - App Entry Point

/// SwiftUI's `WindowGroup` can't produce a borderless, transparent,
/// click-through window — so we keep `App` minimal and let an
/// `NSApplicationDelegate` build the real window with AppKit.
@main
struct TestDriveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // `Settings` is a Scene that doesn't auto-show a window on launch,
        // which is exactly what we want — the overlay window is created
        // manually in `AppDelegate.applicationDidFinishLaunching`.
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate (the tricky transparency / window setup)

/// Owns the transparent overlay window for the lifetime of the app.
///
/// The interesting macOS-specific tricks are all here. Each one is
/// commented inline so it's clear *why* each flag matters.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }

        // 1) Borderless window — no title bar, no traffic lights, no chrome.
        //    A standard `.titled` window would draw its own background and
        //    title bar even with a clear color, so we strip the style down.
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // 2) Make the window itself visually transparent. AppKit draws an
        //    opaque background unless we explicitly opt out via BOTH
        //    `isOpaque = false` and a clear `backgroundColor`.
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false

        // 3) Click-through: mouse clicks fall straight through to whatever
        //    app is underneath. Without this, you'd be unable to click your
        //    desktop, dock, or other windows.
        window.ignoresMouseEvents = true

        // 4) Float above ordinary windows. `.floating` sits over normal apps;
        //    `.screenSaver` sits over almost everything (including menubar).
        //    `.floating` is friendlier for a demo.
        window.level = .floating

        // 5) Show on every Space, survive fullscreen-app switches, and don't
        //    appear in cmd-tab cycling.
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        // 6) Keep the window object alive even if the user (somehow) closes it.
        window.isReleasedWhenClosed = false

        // Mount our SwiftUI content. The hosting view inherits transparency
        // from the parent window automatically.
        window.contentView = NSHostingView(
            rootView: BouncingBallsView(size: screen.frame.size)
        )

        // `orderFrontRegardless` shows the window without making it key,
        // which is exactly what we want for a non-interactive overlay.
        window.orderFrontRegardless()
        overlayWindow = window
    }
}

// MARK: - SwiftUI Wrapper

/// Hosts an `SCNView` inside SwiftUI with a transparent background.
struct BouncingBallsView: NSViewRepresentable {
    let size: CGSize

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView(frame: NSRect(origin: .zero, size: size))
        view.scene = BouncingBallsScene(size: size)

        // CRUCIAL: tell SCNView to clear to transparent pixels each frame,
        // otherwise it paints an opaque black background and ruins the effect.
        view.backgroundColor = .clear

        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isPlaying = true
        view.autoresizingMask = [.width, .height]
        return view
    }

    func updateNSView(_ nsView: SCNView, context: Context) {}
}

// MARK: - Scene

/// The SceneKit scene that owns the camera, lights, walls, and balls.
///
/// World units are roughly equal to screen pixels: 1 unit ≈ 1 point.
/// That makes positioning straightforward (the floor is at
/// `-screenHeight / 2`, etc.) at the cost of needing to scale physics
/// gravity up from the default of -9.8.
final class BouncingBallsScene: SCNScene {

    // Tuning knobs — feel free to tweak.
    private let minBallRadius: CGFloat = 22
    private let maxBallRadius: CGFloat = 55
    private let maxBalls = 100
    private let spawnInterval: TimeInterval = 0.35

    /// Reference radius used to derive each ball's mass from a base mass.
    /// Mass scales with r³ so the big balls have realistic heft.
    private let referenceRadius: CGFloat = 40
    private let referenceMass: CGFloat = 0.8
    private let screenSize: CGSize

    private var halfWidth: CGFloat { screenSize.width / 2 }
    private var halfHeight: CGFloat { screenSize.height / 2 }

    private var spawnTimer: Timer?
    private var safetyTimer: Timer?

    /// Toy-ball palette.
    private let ballColors: [NSColor] = [
        .systemRed,
        .systemBlue,
        .systemGreen,
        .systemYellow,
        .systemPurple
    ]

    // MARK: Initializer

    /// Creates a scene sized for the given screen.
    /// - Parameter size: The pixel size of the overlay window. Used to
    ///   place walls, the camera, and lighting.
    init(size: CGSize) {
        self.screenSize = size
        super.init()

        // Default SceneKit gravity (-9.8 units/s²) is too gentle when
        // 1 unit ≈ 1 pixel. This setting gives a satisfying weight to
        // the drop; if the pile starts to misbehave again, this is the
        // first knob to turn back down.
        physicsWorld.gravity = SCNVector3(0, -2000, 0)

        // Finer physics steps so fast-falling balls don't tunnel through
        // each other between render frames. At our scale, balls can travel
        // ~40 units/frame at terminal speed, which is half a ball diameter
        // — enough to skip a collision at the default 1/60s step.
        physicsWorld.timeStep = 1.0 / 240.0

        setUpCamera()
        setUpLights()
        setUpWalls()
        startSpawning()
        startSafetyMonitor()
    }

    required init?(coder: NSCoder) {
        fatalError("BouncingBallsScene does not support NSCoding.")
    }

    deinit {
        spawnTimer?.invalidate()
        safetyTimer?.invalidate()
    }

    // MARK: Setup

    /// Orthographic camera looking straight at the XY plane. Orthographic
    /// projection keeps the visible region a perfect rectangle so balls
    /// don't appear to shrink as they move sideways.
    private func setUpCamera() {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = Double(halfHeight) // visible half-height
        camera.zNear = 1
        camera.zFar = 5000

        let node = SCNNode()
        node.camera = camera
        node.position = SCNVector3(0, 0, 1000)
        rootNode.addChildNode(node)
    }

    private func setUpLights() {
        // Ambient fill so shadowed sides aren't pitch-black.
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 400
        ambient.color = NSColor.white
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        rootNode.addChildNode(ambientNode)

        // Directional key light — the one that casts soft shadows.
        let key = SCNLight()
        key.type = .directional
        key.intensity = 1200
        key.color = NSColor.white
        key.castsShadow = true
        key.shadowMode = .deferred                          // softer, better quality
        key.shadowRadius = 8                                // blur radius -> softness
        key.shadowSampleCount = 16                          // higher = smoother shadows
        key.shadowColor = NSColor(white: 0, alpha: 0.35)
        key.orthographicScale = max(halfWidth, halfHeight) * 1.2
        key.zNear = 1
        key.zFar = 5000

        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.position = SCNVector3(halfWidth * 0.4, halfHeight, 1000)
        keyNode.look(at: SCNVector3(0, -halfHeight, 0))
        rootNode.addChildNode(keyNode)

        // Environment map — gives PBR materials something to reflect, so
        // the balls read as "glossy plastic" instead of flat-shaded.
        // A real shipping app would load an HDRI here; we build one on the fly.
        lightingEnvironment.contents = makeEnvironmentMap()
        lightingEnvironment.intensity = 0.9
    }

    /// Invisible static walls along left, right, floor, and front/back.
    ///
    /// Front/back walls pin the balls into a thin Z slab so the
    /// orthographic camera can't show "overlap" caused by Z drift.
    /// Without them, rolling friction can scatter balls across many
    /// units of depth, which looks like collision failure on screen
    /// even when physics is correctly maintaining 3D separation.
    ///
    /// The floor is also made very deep: under heavy pile-up pressure
    /// SceneKit's solver can let a ball penetrate a wall by a few
    /// units per frame. A 1000-unit-deep slab ensures any squeezed
    /// ball stays inside the body and gets pushed back up rather than
    /// punching all the way through.
    private func setUpWalls() {
        let sideThickness: CGFloat = 80
        let floorThickness: CGFloat = 1000
        let zClearance: CGFloat = maxBallRadius + 5    // largest ball can move ±5 in Z

        // Floor — top face stays flush with the visible bottom (y = -halfHeight).
        addWall(
            size: SCNVector3(screenSize.width + sideThickness * 2, floorThickness, sideThickness),
            position: SCNVector3(0, -halfHeight - floorThickness / 2, 0)
        )
        // Left wall
        addWall(
            size: SCNVector3(sideThickness, screenSize.height * 2, sideThickness),
            position: SCNVector3(-halfWidth - sideThickness / 2, 0, 0)
        )
        // Right wall
        addWall(
            size: SCNVector3(sideThickness, screenSize.height * 2, sideThickness),
            position: SCNVector3(halfWidth + sideThickness / 2, 0, 0)
        )
        // Front wall — camera-facing side. Invisible + non-shadow-casting so
        // it doesn't show up on screen and doesn't block the key light.
        addWall(
            size: SCNVector3(screenSize.width * 1.5, screenSize.height * 1.5, 20),
            position: SCNVector3(0, 0, zClearance + 10),
            castsShadow: false
        )
        // Back wall
        addWall(
            size: SCNVector3(screenSize.width * 1.5, screenSize.height * 1.5, 20),
            position: SCNVector3(0, 0, -(zClearance + 10)),
            castsShadow: false
        )
    }

    private func addWall(size: SCNVector3, position: SCNVector3, castsShadow: Bool = true) {
        let box = SCNBox(
            width: CGFloat(size.x),
            height: CGFloat(size.y),
            length: CGFloat(size.z),
            chamferRadius: 0
        )
        // `transparency = 0` makes the material completely see-through.
        // (In SceneKit, 0 = fully transparent, 1 = fully opaque.)
        box.firstMaterial?.transparency = 0

        let node = SCNNode(geometry: box)
        node.position = position
        node.castsShadow = castsShadow
        node.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(geometry: box, options: nil)
        )
        node.physicsBody?.restitution = 0.85    // hard, lively surface
        node.physicsBody?.friction = 0.9        // grippy floor
        rootNode.addChildNode(node)
    }

    // MARK: Spawning

    private func startSpawning() {
        spawnTimer = Timer.scheduledTimer(
            withTimeInterval: spawnInterval,
            repeats: true
        ) { [weak self] _ in
            self?.spawnBall()
        }
    }

    /// Adds one new ball just above the visible area so it falls into view.
    /// When the live count hits `maxBalls`, the scene resets.
    private func spawnBall() {
        let liveBalls = rootNode.childNodes.filter { $0.physicsBody?.type == .dynamic }
        if liveBalls.count >= maxBalls {
            resetBalls()
            return
        }

        let radius = CGFloat.random(in: minBallRadius...maxBallRadius)
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 48        // smoother silhouette

        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = ballColors.randomElement() ?? .systemRed
        material.metalness.contents = 0.0       // rubber/plastic, not metal
        material.roughness.contents = 0.25      // glossy
        material.clearCoat.contents = 0.6       // candy-coat highlight pass
        material.clearCoatRoughness.contents = 0.1
        sphere.firstMaterial = material

        let ball = SCNNode(geometry: sphere)
        ball.castsShadow = true
        // Start above the visible area so the ball drops *into* the screen.
        ball.position = SCNVector3(
            CGFloat.random(in: -halfWidth + radius ... halfWidth - radius),
            halfHeight + radius * CGFloat.random(in: 2...4),
            0
        )

        let body = SCNPhysicsBody(
            type: .dynamic,
            shape: SCNPhysicsShape(geometry: sphere, options: nil)
        )
        // Stacking-friendly tuning. Higher friction + damping +
        // moderate restitution keeps the pile stable; the solver only
        // has to fight a little overlap per frame instead of a lot.
        // Mass scales with volume (r³) so bigger balls actually feel heavier.
        body.mass = referenceMass * pow(radius / referenceRadius, 3)
        body.restitution = 0.95         // near-perfectly elastic super-ball
        body.friction = 0.8             // grippy surfaces so balls don't slide into wedges
        body.rollingFriction = 0.3      // resists rolling forever after coming to rest
        body.damping = 0.02             // barely any drag so bounces persist
        body.angularDamping = 0.2       // bleeds spin
        body.allowsResting = true
        // Swept-collision threshold: if the ball moves more than half its
        // radius in one step, SceneKit uses CCD to catch the collision.
        body.continuousCollisionDetectionThreshold = radius * 0.5

        // A little random horizontal kick + spin for character.
        body.velocity = SCNVector3(CGFloat.random(in: -150...150), 0, 0)
        body.angularVelocity = SCNVector4(
            CGFloat.random(in: -1...1),
            CGFloat.random(in: -1...1),
            CGFloat.random(in: -1...1),
            CGFloat.random(in: 1...6)
        )

        ball.physicsBody = body
        rootNode.addChildNode(ball)
    }

    /// Clears every ball from the scene so we can start the pile over.
    private func resetBalls() {
        for node in rootNode.childNodes where node.physicsBody?.type == .dynamic {
            node.removeFromParentNode()
        }
    }

    // MARK: Safety Monitor

    /// Per-frame check that snaps any ball that has somehow escaped past
    /// the floor back inside the bounds. Bullet's solver can let a ball
    /// squeeze through a static body under stacking pressure no matter
    /// how thick the wall is — this guarantees that never reaches the eye.
    private func startSafetyMonitor() {
        safetyTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            self?.catchEscapees()
        }
    }

    private func catchEscapees() {
        for node in rootNode.childNodes where node.physicsBody?.type == .dynamic {
            guard let body = node.physicsBody else { continue }
            let pos = node.presentation.position
            let radius = (node.geometry as? SCNSphere)?.radius ?? referenceRadius

            if pos.y < -halfHeight {
                // Ball fell through the floor — fully reset to a safe spot.
                let clampedX = min(max(pos.x, -halfWidth + radius), halfWidth - radius)
                body.clearAllForces()
                body.velocity = SCNVector3(0, 0, 0)
                body.angularVelocity = SCNVector4(0, 1, 0, 0)
                node.position = SCNVector3(clampedX, -halfHeight + radius, 0)
                body.resetTransform()
            } else if abs(pos.z) > 0.5 {
                // Pin the ball back onto the z = 0 plane. Required because
                // the orthographic camera projects 3D depth out, so any z
                // drift shows up on screen as false ball-to-ball overlap.
                // Static Z walls can't do this for us once we vary ball
                // sizes — a wall sized for the biggest ball is too far
                // away to constrain the smallest one.
                body.velocity = SCNVector3(body.velocity.x, body.velocity.y, 0)
                node.position = SCNVector3(pos.x, pos.y, 0)
                body.resetTransform()
            }
        }
    }

    // MARK: Environment Map

    /// Builds a soft grey gradient image used as the scene's environment
    /// map. Provides cheap "studio lighting" reflections on PBR balls
    /// without needing to ship an HDRI asset.
    private func makeEnvironmentMap() -> NSImage {
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()
        let gradient = NSGradient(colors: [
            NSColor(calibratedWhite: 1.0, alpha: 1),
            NSColor(calibratedWhite: 0.6, alpha: 1),
            NSColor(calibratedWhite: 0.2, alpha: 1)
        ])
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: -90)
        image.unlockFocus()
        return image
    }
}
