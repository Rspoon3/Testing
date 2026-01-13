//
//  PlinkoScene.swift
//  TestDrive
//
//  Created by Claude on 2026.
//

import SpriteKit
import UIKit

/// Physics categories for collision detection.
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let ball: UInt32 = 1 << 0
    static let peg: UInt32 = 1 << 1
    static let wall: UInt32 = 1 << 2
    static let slot: UInt32 = 1 << 3
}

/// A SpriteKit scene that renders the Plinko game board with physics.
final class PlinkoScene: SKScene, SKPhysicsContactDelegate {

    /// Callback when a ball lands in a slot with a point value.
    var onScoreUpdate: ((Int) -> Void)?

    /// Callback when a ball is consumed.
    var onBallConsumed: (() -> Void)?

    private let pegRadius: CGFloat = 6
    private let ballRadius: CGFloat = 10
    private let rows = 12
    private let horizontalPegSpacing: CGFloat = 55
    private let verticalPegSpacing: CGFloat = 50

    private let slotValues = [100, 50, 25, 10, 5, 10, 25, 50, 100]
    private var slotWidth: CGFloat = 0

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        setupScene()
        setupPhysics()
        setupPegs()
        setupWalls()
        setupSlots()
    }

    // MARK: - Setup

    /// Configures the scene's background and appearance.
    private func setupScene() {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
    }

    /// Configures the physics world properties.
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsWorld.contactDelegate = self
    }

    /// Creates a pyramid-shaped grid of pegs.
    private func setupPegs() {
        let startY = size.height - 120
        let centerX = size.width / 2

        for row in 0..<rows {
            // Pyramid: start with 3 pegs at top, add 1 each row
            let pegsInRow = 3 + row
            let totalWidth = CGFloat(pegsInRow - 1) * horizontalPegSpacing
            let startX = centerX - totalWidth / 2

            for col in 0..<pegsInRow {
                let x = startX + CGFloat(col) * horizontalPegSpacing
                let y = startY - CGFloat(row) * verticalPegSpacing
                createPeg(at: CGPoint(x: x, y: y))
            }
        }
    }

    /// Creates a single peg at the specified position.
    /// - Parameter position: The center point of the peg.
    private func createPeg(at position: CGPoint) {
        let peg = SKShapeNode(circleOfRadius: pegRadius)
        peg.position = position
        peg.fillColor = SKColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)
        peg.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
        peg.lineWidth = 2
        peg.glowWidth = 1

        peg.physicsBody = SKPhysicsBody(circleOfRadius: pegRadius)
        peg.physicsBody?.isDynamic = false
        peg.physicsBody?.restitution = 0.6
        peg.physicsBody?.friction = 0.1
        peg.physicsBody?.categoryBitMask = PhysicsCategory.peg

        addChild(peg)
    }

    /// Creates the boundary walls on the sides of the board.
    private func setupWalls() {
        let wallThickness: CGFloat = 10

        // Left wall
        let leftWall = SKShapeNode(rectOf: CGSize(width: wallThickness, height: size.height))
        leftWall.position = CGPoint(x: wallThickness / 2, y: size.height / 2)
        leftWall.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        leftWall.strokeColor = .clear
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wallThickness, height: size.height))
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        addChild(leftWall)

        // Right wall
        let rightWall = SKShapeNode(rectOf: CGSize(width: wallThickness, height: size.height))
        rightWall.position = CGPoint(x: size.width - wallThickness / 2, y: size.height / 2)
        rightWall.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        rightWall.strokeColor = .clear
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wallThickness, height: size.height))
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        addChild(rightWall)
    }

    /// Creates the scoring slots at the bottom of the board.
    private func setupSlots() {
        let slotCount = slotValues.count
        let totalWidth = size.width - 20
        slotWidth = totalWidth / CGFloat(slotCount)
        let slotHeight: CGFloat = 60
        let startX: CGFloat = 10
        let slotY: CGFloat = slotHeight / 2

        for (index, value) in slotValues.enumerated() {
            let slotX = startX + CGFloat(index) * slotWidth + slotWidth / 2
            createSlot(at: CGPoint(x: slotX, y: slotY), value: value, index: index)
        }

        // Add dividers between slots
        for i in 0...slotCount {
            let dividerX = startX + CGFloat(i) * slotWidth
            createSlotDivider(at: CGPoint(x: dividerX, y: slotHeight / 2), height: slotHeight)
        }
    }

    /// Creates a scoring slot at the specified position.
    /// - Parameters:
    ///   - position: The center point of the slot.
    ///   - value: The point value for this slot.
    ///   - index: The slot index for color calculation.
    private func createSlot(at position: CGPoint, value: Int, index: Int) {
        let slotHeight: CGFloat = 60

        // Background color based on value
        let slot = SKShapeNode(rectOf: CGSize(width: slotWidth - 4, height: slotHeight))
        slot.position = position
        slot.fillColor = colorForValue(value)
        slot.strokeColor = .clear
        slot.name = "slot_\(value)"

        // Physics body for collision detection
        slot.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: slotWidth - 4, height: 10), center: CGPoint(x: 0, y: slotHeight / 2 - 5))
        slot.physicsBody?.isDynamic = false
        slot.physicsBody?.categoryBitMask = PhysicsCategory.slot
        slot.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        slot.userData = ["value": value]

        addChild(slot)

        // Value label
        let label = SKLabelNode(text: "\(value)")
        label.fontSize = 16
        label.fontName = "AvenirNext-Bold"
        label.fontColor = .white
        label.position = CGPoint(x: position.x, y: position.y - 5)
        label.verticalAlignmentMode = .center
        addChild(label)
    }

    /// Creates a divider between scoring slots.
    /// - Parameters:
    ///   - position: The center point of the divider.
    ///   - height: The height of the divider.
    private func createSlotDivider(at position: CGPoint, height: CGFloat) {
        let divider = SKShapeNode(rectOf: CGSize(width: 4, height: height))
        divider.position = position
        divider.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)
        divider.strokeColor = .clear

        divider.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 4, height: height))
        divider.physicsBody?.isDynamic = false
        divider.physicsBody?.categoryBitMask = PhysicsCategory.wall

        addChild(divider)
    }

    /// Returns a color based on the slot's point value.
    /// - Parameter value: The point value.
    /// - Returns: An SKColor representing the slot.
    private func colorForValue(_ value: Int) -> SKColor {
        switch value {
        case 100:
            return SKColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1.0)
        case 50:
            return SKColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0)
        case 25:
            return SKColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        case 10:
            return SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0)
        default:
            return SKColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
        }
    }

    // MARK: - Ball Management

    /// Drops a ball at the specified x position.
    /// - Parameter xPosition: The horizontal position to drop the ball.
    func dropBall(at xPosition: CGFloat) {
        let ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.position = CGPoint(x: xPosition, y: size.height - 50)
        ball.fillColor = SKColor(red: 0.95, green: 0.3, blue: 0.4, alpha: 1.0)
        ball.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.6, alpha: 1.0)
        ball.lineWidth = 2
        ball.glowWidth = 2
        ball.name = "ball"

        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 0.5
        ball.physicsBody?.friction = 0.2
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.angularDamping = 0.1
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.collisionBitMask = PhysicsCategory.peg | PhysicsCategory.wall
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.slot

        // Add slight random horizontal velocity for variety
        let randomDx = CGFloat.random(in: -20...20)
        ball.physicsBody?.velocity = CGVector(dx: randomDx, dy: 0)

        addChild(ball)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Only allow dropping from the top area
        if location.y > size.height - 100 {
            let clampedX = max(30, min(size.width - 30, location.x))
            dropBall(at: clampedX)
            onBallConsumed?()
        }
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        var ballBody: SKPhysicsBody?
        var slotBody: SKPhysicsBody?

        if bodyA.categoryBitMask == PhysicsCategory.ball && bodyB.categoryBitMask == PhysicsCategory.slot {
            ballBody = bodyA
            slotBody = bodyB
        } else if bodyB.categoryBitMask == PhysicsCategory.ball && bodyA.categoryBitMask == PhysicsCategory.slot {
            ballBody = bodyB
            slotBody = bodyA
        }

        if let ballNode = ballBody?.node as? SKShapeNode,
           let slotNode = slotBody?.node as? SKShapeNode,
           let userData = slotNode.userData,
           let value = userData["value"] as? Int {

            // Animate ball disappearing
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let scale = SKAction.scale(to: 0.5, duration: 0.2)
            let group = SKAction.group([fadeOut, scale])
            let remove = SKAction.removeFromParent()

            ballNode.run(SKAction.sequence([group, remove]))

            // Flash the slot
            let originalColor = slotNode.fillColor
            slotNode.fillColor = .white
            let wait = SKAction.wait(forDuration: 0.1)
            let restore = SKAction.run { slotNode.fillColor = originalColor }
            slotNode.run(SKAction.sequence([wait, restore]))

            onScoreUpdate?(value)
        }
    }
}
