//
//  BouncingBallsView.swift
//  Testing
//
//  Created by Ricky on 3/28/25.
//

import SwiftUI

struct BouncingBallsView: View {
    @State private var balls: [Ball] = []
    @State private var lastUpdate = Date()
    @State private var canvasSize: CGSize = .zero
    @State private var hasInitialized = false
    @State private var infectionMode: InfectionMode = .blueInfectsRed
    @State private var speed: CGFloat = 1.5
    
    let ballCount = 50
    let ballRadius: CGFloat = 10
    
    enum InfectionMode {
        case blueInfectsRed
        case redInfectsBlue
    }
    
    var body: some View {
        VStack {
            Slider(value: $speed, in: 0.1...50, step: 0.1)
            Text("Speed \(speed.formatted())")
        
            GeometryReader { geo in
                TimelineView(.animation) { timeline in
                    let now = timeline.date
                    let deltaTime = now.timeIntervalSince(lastUpdate)
                    
                    Canvas { context, _ in
                        for ball in balls {
                            let color = ball.isBlue ? Color.blue : Color.red
                            let rect = CGRect(
                                x: ball.position.x - ballRadius,
                                y: ball.position.y - ballRadius,
                                width: ballRadius * 2,
                                height: ballRadius * 2
                            )
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(color)
                            )
                        }
                    }
                    .drawingGroup()
                    .onAppear {
                        canvasSize = geo.size
                    }
                    .onChange(of: timeline.date) { _, newDate in
                        if !hasInitialized && canvasSize != .zero {
                            initializeBalls(in: canvasSize)
                            hasInitialized = true
                        }
                        
                        if hasInitialized {
                            updateBalls(
                                in: canvasSize,
                                deltaTime: deltaTime
                            )
                            lastUpdate = newDate
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
    
    func initializeBalls(in size: CGSize) {
        balls = (0..<ballCount).map { index in
            let x = CGFloat.random(in: ballRadius...(size.width - ballRadius))
            let y = CGFloat.random(in: ballRadius...(size.height - ballRadius))
            let angle = Double.random(in: 0..<2 * .pi)
            let speedMultiplier = speed * 60.0
            let velocity = CGVector(
                dx: cos(angle) * speedMultiplier,
                dy: sin(angle) * speedMultiplier
            )
            return Ball(
                position: CGPoint(x: x, y: y),
                velocity: velocity,
                isBlue: index == 0
            )
        }
        
        infectionMode = .blueInfectsRed
    }
    
    func updateBalls(in size: CGSize, deltaTime: TimeInterval) {
        var updatedBalls = balls
        
        // Move each ball and check wall collisions
        for i in 0..<updatedBalls.count {
            var ball = updatedBalls[i]
            var pos = ball.position
            var vel = ball.velocity
            
            let direction = CGVector(
                dx: vel.dx / max(1e-5, sqrt(vel.dx * vel.dx + vel.dy * vel.dy)),
                dy: vel.dy / max(1e-5, sqrt(vel.dx * vel.dx + vel.dy * vel.dy))
            )
            let currentVelocity = CGVector(
                dx: direction.dx * speed * 60,
                dy: direction.dy * speed * 60
            )
            pos.x += currentVelocity.dx * deltaTime
            pos.y += currentVelocity.dy * deltaTime
            vel = currentVelocity
            
            if pos.x - ballRadius < 0 || pos.x + ballRadius > size.width {
                vel.dx *= -1
                pos.x = max(ballRadius, min(size.width - ballRadius, pos.x))
            }
            
            if pos.y - ballRadius < 0 || pos.y + ballRadius > size.height {
                vel.dy *= -1
                pos.y = max(ballRadius, min(size.height - ballRadius, pos.y))
            }
            
            ball.position = pos
            ball.velocity = vel
            updatedBalls[i] = ball
        }
        
        // Handle collisions and spreading
        for i in 0..<updatedBalls.count {
            for j in (i + 1)..<updatedBalls.count {
                var a = updatedBalls[i]
                var b = updatedBalls[j]
                
                let dx = b.position.x - a.position.x
                let dy = b.position.y - a.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance < ballRadius * 2 {
                    // Handle infection based on current mode
                    if infectionMode == .blueInfectsRed {
                        if a.isBlue && !b.isBlue {
                            b.isBlue = true
                        } else if b.isBlue && !a.isBlue {
                            a.isBlue = true
                        }
                    } else { // redInfectsBlue
                        if !a.isBlue && b.isBlue {
                            b.isBlue = false
                        } else if !b.isBlue && a.isBlue {
                            a.isBlue = false
                        }
                    }
                    
                    // Elastic collision
                    let delta = CGPoint(x: dx, y: dy)
                    let distSquared = delta.x * delta.x + delta.y * delta.y
                    guard distSquared > 0 else { continue }
                    
                    let vDiff = CGVector(
                        dx: a.velocity.dx - b.velocity.dx,
                        dy: a.velocity.dy - b.velocity.dy
                    )
                    let pDiff = CGVector(dx: delta.x, dy: delta.y)
                    
                    let dot = vDiff.dx * pDiff.dx + vDiff.dy * pDiff.dy
                    let scale = dot / distSquared
                    
                    let impulse = CGVector(
                        dx: scale * pDiff.dx,
                        dy: scale * pDiff.dy
                    )
                    
                    a.velocity.dx -= impulse.dx
                    a.velocity.dy -= impulse.dy
                    b.velocity.dx += impulse.dx
                    b.velocity.dy += impulse.dy
                    
                    // Push apart to prevent overlap
                    let overlap = 0.5 * (2 * ballRadius - distance)
                    let norm = CGVector(dx: delta.x / distance, dy: delta.y / distance)
                    
                    a.position.x -= norm.dx * overlap
                    a.position.y -= norm.dy * overlap
                    b.position.x += norm.dx * overlap
                    b.position.y += norm.dy * overlap
                    
                    updatedBalls[i] = a
                    updatedBalls[j] = b
                }
            }
        }
        
        // Check for mode switching conditions
        let redBalls = updatedBalls.filter { !$0.isBlue }
        let blueBalls = updatedBalls.filter { $0.isBlue }
        
        if infectionMode == .blueInfectsRed && redBalls.count == 1 {
            // Switch to red infects blue mode when only one red ball remains
            infectionMode = .redInfectsBlue
        } else if infectionMode == .redInfectsBlue && blueBalls.count == 1 {
            // Switch back to blue infects red when only one blue ball remains
            infectionMode = .blueInfectsRed
        }
        
        balls = updatedBalls
    }
}

#Preview {
    BouncingBallsView()
}
