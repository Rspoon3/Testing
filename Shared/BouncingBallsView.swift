//
//  BouncingBallsView.swift
//  Testing
//
//  Created by Ricky on 3/28/25.
//

import SwiftUI

struct BouncingBallsView: View {
    @State private var balls: [Ball] = []
    @State private var lastUpdate: Date = Date()
    let ballCount = 50
    let ballRadius: CGFloat = 10
    let speed: CGFloat = 1.447 // meters/sec (1 mph)

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1/60, paused: false)) { timeline in
                let now = timeline.date
                let deltaTime = now.timeIntervalSince(lastUpdate)
                Canvas { context, size in
                    updateBalls(in: size, deltaTime: deltaTime)

                    for ball in balls {
                        let color = ball.isBlue ? Color.blue : Color.red
                        let rect = CGRect(
                            origin: CGPoint(
                                x: ball.position.x - ballRadius,
                                y: ball.position.y - ballRadius
                            ),
                            size: CGSize(width: ballRadius * 2, height: ballRadius * 2)
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(color))
                    }
                }
                .onAppear {
                    initializeBalls(in: geo.size)
                    lastUpdate = now
                }
                .onChange(of: geo.size) { _, newSize in
                    initializeBalls(in: newSize)
                }
                .onChange(of: timeline.date) { _, newDate in
                    lastUpdate = newDate
                }
            }
        }
        .ignoresSafeArea()
    }

    func initializeBalls(in size: CGSize) {
        balls = (0..<ballCount).map { index in
            let x = CGFloat.random(in: ballRadius...(size.width - ballRadius))
            let y = CGFloat.random(in: ballRadius...(size.height - ballRadius))
            let angle = Double.random(in: 0..<2 * .pi)
            let velocity = CGVector(dx: cos(angle) * speed * 60.0, dy: sin(angle) * speed * 60.0)

            return Ball(position: CGPoint(x: x, y: y), velocity: velocity, isBlue: index == 0)
        }
    }

    func updateBalls(in size: CGSize, deltaTime: TimeInterval) {
        var updatedBalls = balls

        for i in 0..<updatedBalls.count {
            var ball = updatedBalls[i]

            var newPosition = CGPoint(
                x: ball.position.x + ball.velocity.dx * deltaTime,
                y: ball.position.y + ball.velocity.dy * deltaTime
            )

            // Wall collisions
            if newPosition.x - ballRadius < 0 || newPosition.x + ballRadius > size.width {
                ball.velocity.dx *= -1
                newPosition.x = max(ballRadius, min(size.width - ballRadius, newPosition.x))
            }
            if newPosition.y - ballRadius < 0 || newPosition.y + ballRadius > size.height {
                ball.velocity.dy *= -1
                newPosition.y = max(ballRadius, min(size.height - ballRadius, newPosition.y))
            }

            ball.position = newPosition
            updatedBalls[i] = ball
        }

        // Blue spreading
        for i in 0..<updatedBalls.count {
            for j in (i + 1)..<updatedBalls.count {
                let dist = distance(updatedBalls[i].position, updatedBalls[j].position)
                if dist < ballRadius * 2 {
                    if updatedBalls[i].isBlue || updatedBalls[j].isBlue {
                        updatedBalls[i].isBlue = true
                        updatedBalls[j].isBlue = true
                    }
                }
            }
        }

        balls = updatedBalls
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
}

struct BouncingBallsView_Previews: PreviewProvider {
    static var previews: some View {
        BouncingBallsView()
    }
}

#Preview {
    BouncingBallsView()
}
