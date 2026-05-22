//
//  ConfettiBorderView.swift
//  TestDrive
//

import AppKit
import SwiftUI

/// Multicolored confetti continuously raining down from the top of the screen.
///
/// Ported from a UIKit `CAEmitterLayer` cannon-blast effect. The original
/// emits a one-shot burst (master `birthRate: 0` driven up to `1` for one
/// second, then dropped to `0`) and ramps gravity from `0` to `4000` over
/// six seconds. For "indefinite fall" we hold the master `birthRate` at `1`
/// and use a single static `yAcceleration` instead of the gravity keyframe —
/// every other parameter (sphere emitter above the top, 360° emission, dual
/// foreground/background layers, horizontal + vertical wave behaviors, and
/// the attractor pulling toward the emitter origin) is preserved so the
/// visual matches the source.
struct ConfettiBorderView: View {

    // MARK: - Body

    var body: some View {
        ConfettiRepresentable()
            .ignoresSafeArea()
    }
}

// MARK: - SwiftUI ↔ AppKit bridge

private struct ConfettiRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfettiNSView { ConfettiNSView() }
    func updateNSView(_ view: ConfettiNSView, context: Context) {}
}

// MARK: - Emitter host view

private final class ConfettiNSView: NSView {

    /// Flip so the layer's coordinate space matches iOS (origin at top-left),
    /// letting the original iOS emitter geometry below translate directly.
    override var isFlipped: Bool { true }

    private let particles = ConfettiParticle.all
    private var hasInstalled = false

    // MARK: - Initializer

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Lifecycle

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Also flip the backing layer's Y axis so sublayer positions read
        // top-down — matches the iOS layer coordinate convention so the
        // ported emitter positions don't need flipping.
        layer?.isGeometryFlipped = true
        installIfReady()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        installIfReady()
        repositionEmitters()
    }

    override func layout() {
        super.layout()
        installIfReady()
        repositionEmitters()
    }

    // MARK: - Private Helpers

    /// Installs the emitter layers the first time the view has a real size
    /// and is in a window. Re-entrant — guarded by `hasInstalled` so it only
    /// fires once even though three lifecycle hooks call it.
    private func installIfReady() {
        guard !hasInstalled,
              window != nil,
              bounds.width > 0,
              bounds.height > 0
        else { return }
        hasInstalled = true
        startEmitters()
    }

    private func startEmitters() {
        let foreground = makeEmitter()
        let background = makeEmitter()

        // Background pieces are half-size, half-opacity, slightly slower for parallax.
        if let cells = background.emitterCells {
            for cell in cells { cell.scale = 0.5 }
        }
        background.opacity = 0.5
        background.speed = 0.95

        for emitter in [foreground, background] {
            // Continuous emission (the source set this to 0 and animated it to 1→0).
            emitter.birthRate = 1
            layer?.addSublayer(emitter)
            addBehaviors(to: emitter)
        }
    }

    /// Re-anchors each emitter to the current bounds on resize.
    private func repositionEmitters() {
        for sublayer in layer?.sublayers ?? [] {
            guard let emitter = sublayer as? CAEmitterLayer else { continue }
            emitter.frame = bounds
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: -20)
            emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        }
    }

    private func makeEmitter() -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.birthRate = 0     // overridden once added to the layer
        emitter.emitterCells = particles.map(makeCell)
        // Wide line just above the top edge so confetti rains across the full
        // screen instead of the source's centred 100×100 sphere.
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        emitter.emitterShape = .line
        emitter.frame = bounds
        emitter.beginTime = CACurrentMediaTime()
        return emitter
    }

    private func makeCell(for particle: ConfettiParticle) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.name = particle.id
        cell.beginTime = 0.1
        cell.birthRate = 8
        cell.contents = particle.image
        cell.emissionLongitude = .pi / 2     // straight down in flipped coords
        cell.emissionRange = .pi / 6         // 30° fan
        cell.lifetime = 6
        cell.spin = 4
        cell.spinRange = 8
        cell.velocity = 0
        cell.velocityRange = 40
        // Gentle, steady gravity. Source ramps this from 0 → 4000 over 6s for
        // its one-shot burst; we want a calm continuous fall instead.
        cell.yAcceleration = 380

        let halfPi = Double.pi / 2
        cell.setValue("plane", forKey: "particleType")
        cell.setValue(Double.pi, forKey: "orientationRange")
        cell.setValue(halfPi, forKey: "orientationLongitude")
        cell.setValue(halfPi, forKey: "orientationLatitude")

        return cell
    }

    // MARK: - Emitter behaviors

    /// Adds the source's horizontal + vertical wave behaviors so the falling
    /// confetti sways and bobs. The original cannon also used an `attractor`
    /// to keep the burst clumped near the muzzle — that's omitted here because
    /// a single attractor anchored to the centre would pull every piece toward
    /// the middle of the screen, defeating the full-width line emitter.
    private func addBehaviors(to emitter: CAEmitterLayer) {
        emitter.setValue(
            [horizontalWave(), verticalWave()],
            forKey: "emitterBehaviors"
        )
    }

    private func horizontalWave() -> NSObject? {
        let behavior = makeBehavior(type: "wave")
        behavior?.setValue([100, 0, 0], forKeyPath: "force")
        behavior?.setValue(0.5, forKeyPath: "frequency")
        return behavior
    }

    private func verticalWave() -> NSObject? {
        let behavior = makeBehavior(type: "wave")
        behavior?.setValue([0, 200, 0], forKeyPath: "force")
        behavior?.setValue(3, forKeyPath: "frequency")
        return behavior
    }

    /// Constructs a `CAEmitterBehavior` via reflection — the class is private
    /// API but ships in QuartzCore on every modern Apple platform.
    private func makeBehavior(type: String) -> NSObject? {
        guard let cls = NSClassFromString("CAEmitterBehavior") as? NSObject.Type else { return nil }
        let selector = NSSelectorFromString("behaviorWithType:")
        let imp = cls.method(for: selector)
        let fn = unsafeBitCast(imp, to: (@convention(c) (Any?, Selector, Any?) -> NSObject).self)
        return fn(cls, selector, type)
    }
}

// MARK: - Particle

private final class ConfettiParticle {

    enum Shape {
        case rectangle, circle
        var rect: CGRect {
            switch self {
            case .rectangle: CGRect(x: 0, y: 0, width: 6.5, height: 4)
            case .circle: CGRect(x: 0, y: 0, width: 4, height: 4)
            }
        }
    }

    let id = UUID().uuidString
    let image: CGImage

    init(color: NSColor, shape: Shape) {
        let rect = shape.rect
        // Draw at 2× and let Core Animation downscale for crisp edges.
        let scale: CGFloat = 2
        let context = CGContext(
            data: nil,
            width: Int(rect.width * scale),
            height: Int(rect.height * scale),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.scaleBy(x: scale, y: scale)
        context.setFillColor(color.cgColor)
        switch shape {
        case .rectangle: context.fill(rect)
        case .circle: context.fillEllipse(in: rect)
        }
        image = context.makeImage()!
    }

    /// All particles in the rotation: every (color × shape) combination.
    static let all: [ConfettiParticle] = {
        let colors: [NSColor] = [
            NSColor(red: 149/255, green: 58/255, blue: 255/255, alpha: 1),
            NSColor(red: 255/255, green: 195/255, blue: 41/255, alpha: 1),
            NSColor(red: 255/255, green: 101/255, blue: 26/255, alpha: 1),
            NSColor(red: 123/255, green: 92/255, blue: 255/255, alpha: 1),
            NSColor(red: 76/255, green: 126/255, blue: 255/255, alpha: 1),
            NSColor(red: 71/255, green: 192/255, blue: 255/255, alpha: 1),
            NSColor(red: 255/255, green: 47/255, blue: 39/255, alpha: 1),
            NSColor(red: 255/255, green: 91/255, blue: 134/255, alpha: 1),
            NSColor(red: 233/255, green: 122/255, blue: 208/255, alpha: 1)
        ]
        let shapes: [Shape] = [.rectangle, .circle]
        return shapes.flatMap { shape in
            colors.map { ConfettiParticle(color: $0, shape: shape) }
        }
    }()
}

#Preview {
    ConfettiBorderView()
        .frame(width: 800, height: 500)
        .background(.black)
}
