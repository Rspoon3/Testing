//
//  BorderTrace.swift
//  Testing
//
//  Created by Ricky Witherspoon on 7/25/25.
//

import SwiftUI

struct BorderTraceShape: Shape {
    var progress: Double
    var sliceWidth: Double
    var cornerRadius: Double
    var borderPosition: BorderPosition
    var lineWidth: Double
    
    enum BorderPosition {
        case inside
        case outside
        case center
    }
    
    var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(progress, sliceWidth)
        }
        set {
            progress = newValue.first
            sliceWidth = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        guard sliceWidth > 0 else { return Path() }
        
        // Adjust rect based on border position and stroke width
        let adjustedRect: CGRect
        let adjustedCornerRadius: Double
        
        switch borderPosition {
        case .inside:
            // For inside stroke, inset by full line width (not half)
            adjustedRect = rect.insetBy(dx: lineWidth, dy: lineWidth)
            adjustedCornerRadius = max(0, cornerRadius - lineWidth)
        case .outside:
            // For outside stroke, keep original rect since overlay extends beyond bounds
            adjustedRect = rect
            adjustedCornerRadius = cornerRadius
        case .center:
            // For center stroke, inset by half line width
            adjustedRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            adjustedCornerRadius = max(0, cornerRadius - lineWidth / 2)
        }
        
        let perimeter = calculatePerimeter(for: adjustedRect, cornerRadius: adjustedCornerRadius)
        let totalLength = perimeter
        
        // Calculate start and end positions based on progress and slice width
        let sliceLength = (sliceWidth / 360.0) * totalLength
        let startPosition = progress * totalLength
        let endPosition = startPosition + sliceLength
        
        var path = Path()
        
        // Create the border trace path
        addBorderSegment(to: &path, in: adjustedRect, from: startPosition, to: endPosition, totalLength: totalLength, cornerRadius: adjustedCornerRadius)
        
        return path
    }
    
    private func calculatePerimeter(for rect: CGRect, cornerRadius: Double) -> Double {
        let width = rect.width
        let height = rect.height
        let straightEdges = 2 * (width + height) - 8 * cornerRadius
        let corners = 2 * .pi * cornerRadius
        return straightEdges + corners
    }
    
    private func addBorderSegment(to path: inout Path, in rect: CGRect, from start: Double, to end: Double, totalLength: Double, cornerRadius: Double) {
        let width = rect.width
        let height = rect.height
        let cr = cornerRadius
        
        // Define the segments of the border (top, right, bottom, left with corners)
        let topLength = width - 2 * cr
        let topRightCornerLength = .pi * cr / 2
        let rightLength = height - 2 * cr
        let bottomRightCornerLength = .pi * cr / 2
        let bottomLength = width - 2 * cr
        let bottomLeftCornerLength = .pi * cr / 2
        let leftLength = height - 2 * cr
        let topLeftCornerLength = .pi * cr / 2
        
        var currentLength: Double = 0
        var hasStarted = false
        
        // Helper function to add line segment if within range
        func addSegmentIfInRange(from startPoint: CGPoint, to endPoint: CGPoint, segmentLength: Double) {
            let segmentStart = currentLength
            let segmentEnd = currentLength + segmentLength
            
            if end >= segmentStart && start <= segmentEnd {
                let relativeStart = max(0, (start - segmentStart) / segmentLength)
                let relativeEnd = min(1, (end - segmentStart) / segmentLength)
                
                let actualStart = CGPoint(
                    x: startPoint.x + (endPoint.x - startPoint.x) * relativeStart,
                    y: startPoint.y + (endPoint.y - startPoint.y) * relativeStart
                )
                let actualEnd = CGPoint(
                    x: startPoint.x + (endPoint.x - startPoint.x) * relativeEnd,
                    y: startPoint.y + (endPoint.y - startPoint.y) * relativeEnd
                )
                
                if !hasStarted {
                    path.move(to: actualStart)
                    hasStarted = true
                }
                path.addLine(to: actualEnd)
            }
            currentLength += segmentLength
        }
        
        // Helper function to add arc segment if within range
        func addArcIfInRange(center: CGPoint, radius: Double, startAngle: Double, endAngle: Double, segmentLength: Double) {
            let segmentStart = currentLength
            let segmentEnd = currentLength + segmentLength
            
            if end >= segmentStart && start <= segmentEnd {
                let relativeStart = max(0, (start - segmentStart) / segmentLength)
                let relativeEnd = min(1, (end - segmentStart) / segmentLength)
                
                let actualStartAngle = startAngle + (endAngle - startAngle) * relativeStart
                let actualEndAngle = startAngle + (endAngle - startAngle) * relativeEnd
                
                if !hasStarted {
                    let startPoint = CGPoint(
                        x: center.x + radius * cos(actualStartAngle),
                        y: center.y + radius * sin(actualStartAngle)
                    )
                    path.move(to: startPoint)
                    hasStarted = true
                }
                
                path.addArc(center: center, radius: radius, startAngle: Angle(radians: actualStartAngle), endAngle: Angle(radians: actualEndAngle), clockwise: false)
            }
            currentLength += segmentLength
        }
        
        // Top edge (left to right, excluding corners)
        addSegmentIfInRange(
            from: CGPoint(x: cr, y: 0),
            to: CGPoint(x: width - cr, y: 0),
            segmentLength: topLength
        )
        
        // Top-right corner
        addArcIfInRange(
            center: CGPoint(x: width - cr, y: cr),
            radius: cr,
            startAngle: -Double.pi / 2,
            endAngle: 0,
            segmentLength: topRightCornerLength
        )
        
        // Right edge (top to bottom, excluding corners)
        addSegmentIfInRange(
            from: CGPoint(x: width, y: cr),
            to: CGPoint(x: width, y: height - cr),
            segmentLength: rightLength
        )
        
        // Bottom-right corner
        addArcIfInRange(
            center: CGPoint(x: width - cr, y: height - cr),
            radius: cr,
            startAngle: 0,
            endAngle: Double.pi / 2,
            segmentLength: bottomRightCornerLength
        )
        
        // Bottom edge (right to left, excluding corners)
        addSegmentIfInRange(
            from: CGPoint(x: width - cr, y: height),
            to: CGPoint(x: cr, y: height),
            segmentLength: bottomLength
        )
        
        // Bottom-left corner
        addArcIfInRange(
            center: CGPoint(x: cr, y: height - cr),
            radius: cr,
            startAngle: Double.pi / 2,
            endAngle: Double.pi,
            segmentLength: bottomLeftCornerLength
        )
        
        // Left edge (bottom to top, excluding corners)
        addSegmentIfInRange(
            from: CGPoint(x: 0, y: height - cr),
            to: CGPoint(x: 0, y: cr),
            segmentLength: leftLength
        )
        
        // Top-left corner
        addArcIfInRange(
            center: CGPoint(x: cr, y: cr),
            radius: cr,
            startAngle: Double.pi,
            endAngle: 3 * Double.pi / 2,
            segmentLength: topLeftCornerLength
        )
    }
}

struct BorderTrace: View {
    // Animation configuration
    let rotationDuration: Double
    let pauseDuration: Double
    let maxSliceWidth: Double
    let convergenceProgress: Double // 0.0-1.0 where slice converges (0 = top-left corner)
    let gradientColors: [Color]
    let opacityAnimationPercentage: Double?
    let cornerRadius: Double
    let lineWidth: Double
    let borderPosition: BorderTraceShape.BorderPosition
    
    init(
        rotationDuration: Double = 6.0,
        pauseDuration: Double = 2.0,
        maxSliceWidth: Double = 90.0,
        convergenceProgress: Double = 0.0,
        gradientColors: [Color] = [.white, .purple],
        opacityAnimationPercentage: Double? = nil,
        cornerRadius: Double = 8.0,
        lineWidth: Double = 3.0,
        borderPosition: BorderTraceShape.BorderPosition = .outside
    ) {
        self.rotationDuration = rotationDuration
        self.pauseDuration = pauseDuration
        self.maxSliceWidth = maxSliceWidth
        self.convergenceProgress = convergenceProgress
        self.gradientColors = gradientColors
        self.opacityAnimationPercentage = opacityAnimationPercentage
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.borderPosition = borderPosition
    }
    
    func calculateAnimationValues(for progress: Double) -> (progress: Double, sliceWidth: Double, opacity: Double) {
        let totalDuration = rotationDuration + pauseDuration
        let animationPhaseRatio = rotationDuration / totalDuration
        
        if progress < animationPhaseRatio {
            let animationProgress = progress / animationPhaseRatio
            let currentProgress = animationProgress
            // Adjust sine wave so width is 0 at start and end
            let sliceWidth = sin(animationProgress * .pi) * maxSliceWidth
            
            // Calculate opacity based on animation percentage
            let opacity: Double
            if let percentage = opacityAnimationPercentage {
                let fadePercentage = min(max(percentage, 0), 1) // Clamp between 0 and 1
                
                if animationProgress < fadePercentage {
                    // Fade in phase
                    opacity = animationProgress / fadePercentage
                } else if animationProgress > (1 - fadePercentage) {
                    // Fade out phase
                    opacity = (1 - animationProgress) / fadePercentage
                } else {
                    // Full opacity phase
                    opacity = 1.0
                }
            } else {
                // No opacity animation
                opacity = 1.0
            }
            
            return (currentProgress, sliceWidth, opacity)
        } else { // Pause phase
            return (convergenceProgress, 0, 0)
        }
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let cycleDuration = rotationDuration + pauseDuration
            let cycleProgress = elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
            
            let values = calculateAnimationValues(for: cycleProgress)
            
            Group {
                if values.sliceWidth > 0 {
                    BorderTraceShape(
                        progress: values.progress,
                        sliceWidth: values.sliceWidth,
                        cornerRadius: cornerRadius,
                        borderPosition: borderPosition,
                        lineWidth: lineWidth
                    )
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .opacity(values.opacity)
                } else {
                    Color.clear
                }
            }
        }
    }
}

extension View {
    func animatedBorder(
        rotationDuration: Double = 6.0,
        pauseDuration: Double = 2.0,
        maxSliceWidth: Double = 90.0,
        convergenceProgress: Double = 0.0,
        gradientColors: [Color] = [.white, .purple],
        opacityAnimationPercentage: Double? = nil,
        cornerRadius: Double = 8.0,
        lineWidth: Double = 3.0,
        borderPosition: BorderTraceShape.BorderPosition = .outside
    ) -> some View {
        self.overlay {
            BorderTrace(
                rotationDuration: rotationDuration,
                pauseDuration: pauseDuration,
                maxSliceWidth: maxSliceWidth,
                convergenceProgress: convergenceProgress,
                gradientColors: gradientColors,
                opacityAnimationPercentage: opacityAnimationPercentage,
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                borderPosition: borderPosition
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("Outside Border") { }
            .padding(16)
            .background(Color.white)
            .foregroundStyle(.purple)
            .cornerRadius(8)
            .animatedBorder(
                rotationDuration: 4,
                pauseDuration: 0,
                maxSliceWidth: 90,
                convergenceProgress: 0,
                gradientColors: [.white, .purple],
                opacityAnimationPercentage: 0.25,
                cornerRadius: 8,
                lineWidth: 3,
                borderPosition: .outside
            )
        
        Button("Inside Border") { }
            .padding(16)
            .background(Color.white)
            .foregroundStyle(.purple)
            .cornerRadius(8)
            .animatedBorder(
                rotationDuration: 4,
                pauseDuration: 0,
                maxSliceWidth: 90,
                convergenceProgress: 0,
                gradientColors: [.red, .orange],
                opacityAnimationPercentage: 0.25,
                cornerRadius: 8,
                lineWidth: 3,
                borderPosition: .inside
            )
    }
    .padding(24)
    .background(Color.purple)
}
