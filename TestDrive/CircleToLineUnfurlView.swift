//
//  CircleToLineUnfurlView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 12/1/25.

import SwiftUI

struct Ball: Identifiable {
    let id: Int
    let index: Int
}

struct CuppedHandsUnfurlView: View {
    @State private var progress: CGFloat = 0.0   // 0 = closed circle, 1 = full line
    private let balls: [Ball] = (0..<63).map { Ball(id: $0, index: $0) }

    // MARK: - Body

    var body: some View {
        VStack {
            GeometryReader { geo in
                let size   = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = size * 0.35

                ZStack {
                    // Circle guide
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                        .foregroundStyle(.gray.opacity(0.25))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)

                    // Top line guide
                    Path { path in
                        let y = center.y - radius
                        path.move(to: CGPoint(x: center.x - radius, y: y))
                        path.addLine(to: CGPoint(x: center.x + radius, y: y))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .foregroundStyle(.gray.opacity(0.25))

                    ForEach(balls) { ball in
                        let position = ballPosition(
                            index: ball.index,
                            center: center,
                            radius: radius,
                            progress: progress
                        )

                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                            .position(position)
                    }
                }
            }
            .padding()

            Slider(value: $progress, in: 0...1)
                .padding(.horizontal)

            Text(String(format: "Progress: %.2f", progress))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Private Helpers

    /// Calculates the position of a ball based on its index and the current progress.
    /// - Parameters:
    ///   - index: The index of the ball in the circle.
    ///   - center: The center point of the circle.
    ///   - radius: The radius of the circle.
    ///   - progress: The unfurl progress (0 = closed circle, 1 = full line at top).
    /// - Returns: The calculated position for the ball.
    private func ballPosition(
        index: Int,
        center: CGPoint,
        radius: CGFloat,
        progress: CGFloat
    ) -> CGPoint {
        // --- 1) START: on the circle, with a half-step angle offset so no ball is exactly at the top ---
        let count = CGFloat(balls.count)
        let angle = 2 * .pi * (CGFloat(index) + 0.5) / count  // +0.5 avoids a ball exactly at angle = 0
        let startX = center.x + radius * cos(angle)
        let startY = center.y + radius * sin(angle)

        // --- 2) END: evenly spaced along a straight line at the top of the circle ---
        // fraction in [0, 1] across all balls
        let fraction = CGFloat(index) / (count - 1)
        let endX = center.x - radius + 2 * radius * fraction
        let endY = center.y - radius

        // --- 3) "Cupped hands" weighting: bottom moves least at first, top moves most ---
        // vertical factor: 0 at bottom, 1 at top
        let bottomY = center.y + radius
        let topY = center.y - radius
        let verticalFactor = max(0, min(1, (bottomY - startY) / (bottomY - topY)))
        // So:
        //  - bottom point → verticalFactor ≈ 0
        //  - top point    → verticalFactor ≈ 1

        // Weight: bottom moves slower, top moves faster
        // At progress = 1, everyone must reach the line → clamp to 1.
        let weight = 0.3 + 0.7 * verticalFactor       // 0.3 at bottom, 1.0 at top
        let localProgress = min(1, progress * weight) // slow start for bottom, full at the end

        // --- 4) Interpolate between circle and line ---
        let x = startX + (endX - startX) * localProgress
        let y = startY + (endY - startY) * localProgress

        return CGPoint(x: x, y: y)
    }
}

#Preview {
    CuppedHandsUnfurlView()
}
