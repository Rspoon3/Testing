//
//  AnimatedRectangle.swift
//  TestDrive
//
//  Adapted from https://github.com/metasidd/Prototype-Siri-Screen-Animation
//  Original by Siddhant Mehta, 2024-06-13.
//

import SwiftUI

/// A rounded rectangle whose perimeter points drift via per-axis sine waves,
/// producing the wavy "breathing" outline used by the Siri animation.
struct AnimatedRectangle: Shape {
    var size: CGSize
    var padding: Double = 8.0
    var cornerRadius: CGFloat
    var t: CGFloat

    var animatableData: CGFloat {
        get { t }
        set { t = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = size.width
        let height = size.height
        let radius = cornerRadius

        let initialPoints = [
            CGPoint(x: padding + radius, y: padding),
            CGPoint(x: width * 0.25 + padding, y: padding),
            CGPoint(x: width * 0.75 + padding, y: padding),
            CGPoint(x: width - padding - radius, y: padding),
            CGPoint(x: width - padding, y: padding + radius),
            CGPoint(x: width - padding, y: height * 0.25 - padding),
            CGPoint(x: width - padding, y: height * 0.75 - padding),
            CGPoint(x: width - padding, y: height - padding - radius),
            CGPoint(x: width - padding - radius, y: height - padding),
            CGPoint(x: width * 0.75 - padding, y: height - padding),
            CGPoint(x: width * 0.25 - padding, y: height - padding),
            CGPoint(x: padding + radius, y: height - padding),
            CGPoint(x: padding, y: height - padding - radius),
            CGPoint(x: padding, y: height * 0.75 - padding),
            CGPoint(x: padding, y: height * 0.25 - padding),
            CGPoint(x: padding, y: padding + radius)
        ]

        let points = initialPoints.map { point in
            CGPoint(
                x: point.x + 10 * sin(t + point.y * 0.1),
                y: point.y + 10 * sin(t + point.x * 0.1)
            )
        }

        path.move(to: CGPoint(x: padding, y: padding + radius))

        for point in points[0...2] {
            path.addLine(to: point)
        }
        for point in points[4...7] {
            path.addLine(to: point)
        }
        for point in points[8...10] {
            path.addLine(to: point)
        }
        for point in points[11...14] {
            path.addLine(to: point)
        }

        path.closeSubpath()
        return path
    }
}
