//
//  BouncingBallScene.swift
//  Testing
//
//  Created by Ricky on 3/28/25.
//

import SwiftUI
import SpriteKit

final class BouncingBallScene: SKScene, SKPhysicsContactDelegate {
    enum InfectionMode {
        case blueInfectsRed
        case redInfectsBlue
    }

    let ballCount = 50
    let ballRadius: CGFloat = 10
    let mySpeed: CGFloat = 1.447
    var infectionMode: InfectionMode = .blueInfectsRed

    struct Category {
        static let ball: UInt32 = 0x1 << 0
        static let edge: UInt32 = 0x1 << 1
    }

    override func didMove(to view: SKView) {
        backgroundColor = .white
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        // Create a proper boundary with collision detection
        let boundaryFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let boundary = SKPhysicsBody(edgeLoopFrom: boundaryFrame)
        boundary.friction = 0
        boundary.restitution = 1.0
        boundary.categoryBitMask = Category.edge
        boundary.collisionBitMask = Category.ball
        
        self.physicsBody = boundary

        createBalls()
    }

    func createBalls() {
        removeAllChildren()

        for i in 0..<ballCount {
            let ball = SKShapeNode(circleOfRadius: ballRadius)
            ball.position = CGPoint(
                x: CGFloat.random(in: ballRadius*2...(size.width - ballRadius*2)),
                y: CGFloat.random(in: ballRadius*2...(size.height - ballRadius*2))
            )
            ball.fillColor = i == 0 ? .blue : .red
            ball.name = i == 0 ? "blue" : "red"
            ball.strokeColor = .black
            ball.lineWidth = 1.0

            let physics = SKPhysicsBody(circleOfRadius: ballRadius)
            physics.restitution = 1.0
            physics.linearDamping = 0.0
            physics.friction = 0.0
            physics.allowsRotation = false
            physics.affectedByGravity = false
            physics.categoryBitMask = Category.ball
            physics.contactTestBitMask = Category.ball
            physics.collisionBitMask = Category.ball | Category.edge

            let angle = Double.random(in: 0..<2 * .pi)
            physics.velocity = CGVector(
                dx: cos(angle) * mySpeed * 100.0,
                dy: sin(angle) * mySpeed * 100.0
            )

            ball.physicsBody = physics
            addChild(ball)
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else { return }
        
        // Only process ball-to-ball collisions
        guard let a = nodeA as? SKShapeNode, let b = nodeB as? SKShapeNode,
              a.name != nil && b.name != nil else { return }

        switch infectionMode {
        case .blueInfectsRed:
            if a.name == "blue" && b.name == "red" {
                b.name = "blue"
                b.fillColor = .blue
            } else if b.name == "blue" && a.name == "red" {
                a.name = "blue"
                a.fillColor = .blue
            }

        case .redInfectsBlue:
            if a.name == "red" && b.name == "blue" {
                b.name = "red"
                b.fillColor = .red
            } else if b.name == "red" && a.name == "blue" {
                a.name = "red"
                a.fillColor = .red
            }
        }

        checkInfectionModeSwitch()
    }

    func checkInfectionModeSwitch() {
        let redBalls = children.compactMap { $0 as? SKShapeNode }.filter { $0.name == "red" }
        let blueBalls = children.compactMap { $0 as? SKShapeNode }.filter { $0.name == "blue" }

        if infectionMode == .blueInfectsRed && redBalls.count == 1 {
            infectionMode = .redInfectsBlue
        } else if infectionMode == .redInfectsBlue && blueBalls.count == 1 {
            infectionMode = .blueInfectsRed
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Ensure balls stay within bounds (additional safety check)
        for node in children {
            guard let ball = node as? SKShapeNode, let physics = ball.physicsBody else { continue }
            
            // Apply velocity correction if balls somehow get stuck
            if physics.velocity.dx == 0 && physics.velocity.dy == 0 {
                let angle = Double.random(in: 0..<2 * .pi)
                physics.velocity = CGVector(
                    dx: cos(angle) * mySpeed * 100.0,
                    dy: sin(angle) * mySpeed * 100.0
                )
            }
            
            // Ensure ball stays in bounds if it somehow escapes
            if ball.position.x < ballRadius {
                ball.position.x = ballRadius
                physics.velocity.dx = abs(physics.velocity.dx)
            } else if ball.position.x > size.width - ballRadius {
                ball.position.x = size.width - ballRadius
                physics.velocity.dx = -abs(physics.velocity.dx)
            }
            
            if ball.position.y < ballRadius {
                ball.position.y = ballRadius
                physics.velocity.dy = abs(physics.velocity.dy)
            } else if ball.position.y > size.height - ballRadius {
                ball.position.y = size.height - ballRadius
                physics.velocity.dy = -abs(physics.velocity.dy)
            }
        }
    }
}

struct BouncingBallsSpriteView: View {
    var scene: SKScene {
        let scene = BouncingBallScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .onAppear {
                // Enable visualization of physics bodies for debugging (optional)
                // SKView.viewFor(scene: scene)?.showsPhysics = true
            }
    }
}

#Preview {
    BouncingBallsSpriteView()
}
