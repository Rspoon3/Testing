//
//  AnimatedStrokeStyle.swift
//  Testing
//
//  Created by Ricky Witherspoon on 7/25/25.
//

import SwiftUI

struct AnimatedStrokeStyle {
    let rotationDuration: Double
    let pauseDuration: Double
    let maxSliceWidth: Double
    let convergenceProgress: Double
    let gradientColors: [Color]
    let opacityAnimationPercentage: Double?
    let lineWidth: Double
    
    init(
        rotationDuration: Double = 6.0,
        pauseDuration: Double = 2.0,
        maxSliceWidth: Double = 90.0,
        convergenceProgress: Double = 0.0,
        gradientColors: [Color] = [.white, .purple],
        opacityAnimationPercentage: Double? = nil,
        lineWidth: Double = 3.0
    ) {
        self.rotationDuration = rotationDuration
        self.pauseDuration = pauseDuration
        self.maxSliceWidth = maxSliceWidth
        self.convergenceProgress = convergenceProgress
        self.gradientColors = gradientColors
        self.opacityAnimationPercentage = opacityAnimationPercentage
        self.lineWidth = lineWidth
    }
    
    func calculateAnimationValues(for progress: Double) -> (progress: Double, sliceWidth: Double, opacity: Double) {
        let totalDuration = rotationDuration + pauseDuration
        let animationPhaseRatio = rotationDuration / totalDuration
        
        if progress < animationPhaseRatio {
            let animationProgress = progress / animationPhaseRatio
            let currentProgress = animationProgress
            let sliceWidth = sin(animationProgress * Double.pi) * maxSliceWidth
            
            let opacity: Double
            if let percentage = opacityAnimationPercentage {
                let fadePercentage = min(max(percentage, 0), 1)
                
                if animationProgress < fadePercentage {
                    opacity = animationProgress / fadePercentage
                } else if animationProgress > (1 - fadePercentage) {
                    opacity = (1 - animationProgress) / fadePercentage
                } else {
                    opacity = 1.0
                }
            } else {
                opacity = 1.0
            }
            
            return (currentProgress, sliceWidth, opacity)
        } else {
            return (convergenceProgress, 0, 0)
        }
    }
    
    func createStrokeStyle(progress: Double, sliceWidth: Double) -> StrokeStyle {
        guard sliceWidth > 0 else {
            return StrokeStyle(lineWidth: 0)
        }
        
        // Convert slice width to dash pattern
        // This is a simplified approach - we'll create a dash pattern that approximates the slice
        let circumferenceApprox = 2 * Double.pi * 100 // Approximate circumference for calculation
        let dashLength = (sliceWidth / 360.0) * circumferenceApprox
        let gapLength = circumferenceApprox - dashLength
        
        return StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            dash: [dashLength, gapLength],
            dashPhase: -(progress * circumferenceApprox)
        )
    }
}

struct AnimatedStrokeBorder<S: InsettableShape>: View {
    let shape: S
    let animatedStyle: AnimatedStrokeStyle
    
    init(_ shape: S, style: AnimatedStrokeStyle) {
        self.shape = shape
        self.animatedStyle = style
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let cycleDuration = animatedStyle.rotationDuration + animatedStyle.pauseDuration
            let cycleProgress = elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
            
            let values = animatedStyle.calculateAnimationValues(for: cycleProgress)
            let strokeStyle = animatedStyle.createStrokeStyle(progress: values.progress, sliceWidth: values.sliceWidth)
            
            if values.sliceWidth > 0 {
                shape
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: animatedStyle.gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: strokeStyle
                    )
                    .opacity(values.opacity)
            } else {
                Color.clear
            }
        }
    }
}

extension View {
    func animatedStrokeBorder<S: InsettableShape>(
        _ shape: S,
        rotationDuration: Double = 6.0,
        pauseDuration: Double = 2.0,
        maxSliceWidth: Double = 90.0,
        convergenceProgress: Double = 0.0,
        gradientColors: [Color] = [.white, .purple],
        opacityAnimationPercentage: Double? = nil,
        lineWidth: Double = 3.0
    ) -> some View {
        self.overlay {
            AnimatedStrokeBorder(
                shape,
                style: AnimatedStrokeStyle(
                    rotationDuration: rotationDuration,
                    pauseDuration: pauseDuration,
                    maxSliceWidth: maxSliceWidth,
                    convergenceProgress: convergenceProgress,
                    gradientColors: gradientColors,
                    opacityAnimationPercentage: opacityAnimationPercentage,
                    lineWidth: lineWidth
                )
            )
        }
    }
}

#Preview {
    Button("Get Started") { }
        .padding(16)
        .background(Color.white)
        .foregroundStyle(.purple)
        .cornerRadius(8)
        .animatedStrokeBorder(
            RoundedRectangle(cornerRadius: 8),
            rotationDuration: 4,
            pauseDuration: 0,
            maxSliceWidth: 90,
            gradientColors: [.white, .purple],
            opacityAnimationPercentage: 0.25,
            lineWidth: 3
        )
        .padding(24)
        .background(Color.purple)
}