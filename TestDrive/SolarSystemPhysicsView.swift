//
//  SolarSystemPhysicsView.swift
//  Testing
//
//  Created by Ricky on 3/29/25.
//


import SwiftUI
import SpriteKit

struct SolarSystemPhysicsView: View {
    var scene: SKScene {
        let scene = SolarSystemScene()
        scene.scaleMode = .resizeFill
        scene.speed = 10000
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}

#Preview {
    SolarSystemPhysicsView()
}

import SpriteKit

import SpriteKit

class SolarSystemScene: SKScene {
    let G: CGFloat = 50  // Gravitational constant (tuned for simulation)

    let sunMass: CGFloat = 1000
    let earthMass: CGFloat = 10
    let moonMass: CGFloat = 1

    let sun = SKShapeNode(circleOfRadius: 20)
    let earth = SKShapeNode(circleOfRadius: 8)
    let moon = SKShapeNode(circleOfRadius: 4)

    override func didMove(to view: SKView) {
        backgroundColor = .white
        physicsWorld.gravity = .zero
        physicsWorld.speed = 10.0

        // 🌞 SUN (static)
        sun.fillColor = .orange
        sun.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sun.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        sun.physicsBody?.isDynamic = false
        sun.physicsBody?.mass = sunMass
        addChild(sun)

        // 🌍 EARTH
        let earthDistance: CGFloat = 150
        earth.fillColor = .blue
        earth.position = CGPoint(x: sun.position.x + earthDistance, y: sun.position.y)
        earth.physicsBody = SKPhysicsBody(circleOfRadius: 8)
        earth.physicsBody?.mass = earthMass
        earth.physicsBody?.linearDamping = 0
        earth.physicsBody?.angularDamping = 0

        let vEarth = sqrt(G * sunMass / earthDistance)
        earth.physicsBody?.velocity = CGVector(dx: 0, dy: vEarth)
        addChild(earth)

        // 🌙 MOON
        let moonDistance: CGFloat = 25
        moon.fillColor = .gray
        moon.position = CGPoint(x: earth.position.x + moonDistance, y: earth.position.y)
        moon.physicsBody = SKPhysicsBody(circleOfRadius: 4)
        moon.physicsBody?.mass = moonMass
        moon.physicsBody?.linearDamping = 0
        moon.physicsBody?.angularDamping = 0

        // Calculate moon's orbit velocity
        let vMoon = sqrt(G * earthMass / moonDistance)

        // Get perpendicular direction to Earth–Moon vector
        let dx = moon.position.x - earth.position.x
        let dy = moon.position.y - earth.position.y
        let dist = sqrt(dx*dx + dy*dy)
        let ux = -dy / dist
        let uy = dx / dist

        let vEarthX = earth.physicsBody!.velocity.dx
        let vEarthY = earth.physicsBody!.velocity.dy

        moon.physicsBody?.velocity = CGVector(
            dx: vEarthX + ux * vMoon,
            dy: vEarthY + uy * vMoon
        )

        addChild(moon)
    }

    override func update(_ currentTime: TimeInterval) {
        applyGravity(from: sun, to: earth)
        applyGravity(from: earth, to: moon)
    }

    func applyGravity(from a: SKNode, to b: SKNode) {
        guard let pa = a.physicsBody, let pb = b.physicsBody else { return }

        let dx = a.position.x - b.position.x
        let dy = a.position.y - b.position.y
        let distanceSquared = dx * dx + dy * dy
        let distance = sqrt(distanceSquared)
        guard distance > 1 else { return }

        let direction = CGVector(dx: dx / distance, dy: dy / distance)
        let force = G * pa.mass * pb.mass / distanceSquared

        pb.applyForce(CGVector(dx: direction.dx * force, dy: direction.dy * force))
    }
}
