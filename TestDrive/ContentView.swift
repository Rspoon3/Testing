//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var pulseInterval: Double = 1.5
    @State private var speed: Double = 50
    @State private var intensityScale: Double = 0.6
    @State private var ringLifetime: Double = 6.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = min(size.width, size.height) / 2
                
                // Get current time for smooth animation
                let currentTime = timeline.date.timeIntervalSinceReferenceDate
                
                // Draw pulsing central dot
                let pulseCycle = fmod(currentTime, pulseInterval) / pulseInterval
                let pulseScale = 1.0 + 0.3 * sin(pulseCycle * 2 * .pi)
                let dotRadius = 4.0 * pulseScale
                
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: center.x - dotRadius,
                        y: center.y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )),
                    with: .color(.white)
                )
                
                for i in 0..<10 {
                    // Calculate when this ring was born
                    let ringBirthTime = floor(currentTime / pulseInterval) * pulseInterval - Double(i) * pulseInterval
                    let ringAge = currentTime - ringBirthTime
                    
                    // Only show rings that are actively expanding
                    if ringAge >= 0 && ringAge < ringLifetime {
                        let radius = ringAge * speed
                        
                        if radius <= maxRadius && radius > 0 {
                            // Apply inverse square law: intensity = 1 / (distance^2)
                            let normalizedDistance = max(radius / 50, 0.1) // Base unit, avoid division by zero
                            let intensity = 1.0 / (normalizedDistance * normalizedDistance)
                            
                            // Additional fade based on age to make rings disappear naturally
                            let ageFade = max(0, 1.0 - (ringAge / ringLifetime))
                            let finalOpacity = min(intensity * ageFade * intensityScale, 1.0)
                            
                            if finalOpacity > 0.01 { // Only draw visible rings
                                context.stroke(
                                    Path(ellipseIn: CGRect(
                                        x: center.x - radius,
                                        y: center.y - radius,
                                        width: radius * 2,
                                        height: radius * 2
                                    )),
                                    with: .color(.white.opacity(finalOpacity)),
                                    lineWidth: 2
                                )
                            }
                        }
                    }
                }
            }
        }
        .background(Color.black)
//        .overlay(alignment: .bottom) {
//            VStack {
//                VStack(spacing: 12) {
//                    HStack {
//                        Text("Pulse Interval: \(pulseInterval, specifier: "%.1f")s")
//                            .foregroundColor(.white)
//                            .font(.caption)
//                        Spacer()
//                    }
//                    Slider(value: $pulseInterval, in: 0.5...3.0)
//                        .accentColor(.white)
//                    
//                    HStack {
//                        Text("Speed: \(speed, specifier: "%.0f") px/s")
//                            .foregroundColor(.white)
//                            .font(.caption)
//                        Spacer()
//                    }
//                    Slider(value: $speed, in: 20...100)
//                        .accentColor(.white)
//                    
//                    HStack {
//                        Text("Intensity: \(intensityScale, specifier: "%.2f")")
//                            .foregroundColor(.white)
//                            .font(.caption)
//                        Spacer()
//                    }
//                    Slider(value: $intensityScale, in: 0.1...1.0)
//                        .accentColor(.white)
//                    
//                    HStack {
//                        Text("Ring Lifetime: \(ringLifetime, specifier: "%.1f")s")
//                            .foregroundColor(.white)
//                            .font(.caption)
//                        Spacer()
//                    }
//                    Slider(value: $ringLifetime, in: 2.0...10.0)
//                        .accentColor(.white)
//                }
//                .padding()
//                .background(Color.black.opacity(0.7))
//                .cornerRadius(10)
//                .padding(.horizontal)
//                .padding(.bottom, 20)
//            }
//        }
    }
}

#Preview {
    ContentView()
}
