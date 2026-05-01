//
//  CornerSnapView.swift
//  Shared
//
//  Created by Richard Witherspoon on 6/13/25.
//

import SwiftUI
import Foundation

struct CornerSnapView: View {
    @AppStorage("velocityScale") private var velocityScale: Double = 0.3
    @AppStorage("animationResponse") private var animationResponse: Double = 0.5
    @AppStorage("dampingFraction") private var dampingFraction: Double = 0.75
    @AppStorage("showCornerBounds") private var showCornerBounds: Bool = true
    
    @State private var circlePosition: CGPoint = CGPoint(x: 100, y: 100)
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    private let opacity = 0.1
    
    var body: some View {
        VStack {
            // Controls
            VStack(spacing: 0) {
                HStack {
                    VStack {
                        Text("Velocity Scale: \(velocityScale.formatted(.number.precision(.fractionLength(2))))")
                        Slider(value: $velocityScale, in: 0...1)
                    }
                    Button("Reset") {
                        velocityScale = 0.3
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                HStack {
                    VStack {
                        Text("Animation Speed: \(animationResponse.formatted(.number.precision(.fractionLength(2))))")
                        Slider(value: $animationResponse, in: 0.1...2.0)
                    }
                    Button("Reset") {
                        animationResponse = 0.5
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                HStack {
                    VStack {
                        Text("Damping: \(dampingFraction.formatted(.number.precision(.fractionLength(2))))")
                        Slider(value: $dampingFraction, in: 0.1...1.0)
                    }
                    Button("Reset") {
                        dampingFraction = 0.75
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Toggle("Show Corner Bounds", isOn: $showCornerBounds)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding()
            
            // Circle area
            GeometryReader { geometry in
                ZStack {
                    // Corner bounds indicators
                    if showCornerBounds {
                        let halfWidth = geometry.size.width / 2
                        let halfHeight = geometry.size.height / 2
                        
                        // Top-left quadrant
                        Rectangle()
                            .fill(Color.red.opacity(opacity))
                            .frame(width: halfWidth, height: halfHeight)
                            .position(x: halfWidth / 2, y: halfHeight / 2)
                        
                        // Top-right quadrant
                        Rectangle()
                            .fill(Color.blue.opacity(opacity))
                            .frame(width: halfWidth, height: halfHeight)
                            .position(x: halfWidth + halfWidth / 2, y: halfHeight / 2)
                        
                        // Bottom-left quadrant
                        Rectangle()
                            .fill(Color.green.opacity(opacity))
                            .frame(width: halfWidth, height: halfHeight)
                            .position(x: halfWidth / 2, y: halfHeight + halfHeight / 2)
                        
                        // Bottom-right quadrant
                        Rectangle()
                            .fill(Color.orange.opacity(opacity))
                            .frame(width: halfWidth, height: halfHeight)
                            .position(x: halfWidth + halfWidth / 2, y: halfHeight + halfHeight / 2)
                    }
                    
                    // Main circle
                    Image(systemName: "star.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.white, .blue)
                        .position(circlePosition)
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    isDragging = false
                                    let velocity = value.velocity
                                    
                                    // Calculate current position
                                    let currentX = circlePosition.x + dragOffset.width
                                    let currentY = circlePosition.y + dragOffset.height
                                    
                                    // Lightweight prediction: just extend the velocity a bit
                                    let predictedX = currentX + velocity.width * velocityScale
                                    let predictedY = currentY + velocity.height * velocityScale
                                    
                                    // Find nearest corner to predicted position
                                    let nearestCorner = findNearestCorner(
                                        predictedPosition: CGPoint(x: predictedX, y: predictedY),
                                        in: geometry.size
                                    )
                                    
                                    // Light, bouncy animation
                                    withAnimation(.spring(response: animationResponse, dampingFraction: dampingFraction)) {
                                        circlePosition = nearestCorner
                                        dragOffset = .zero
                                    }
                                }
                        )
                }
            }
            .onAppear {
                // Start in top-right corner
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let safeArea = window.safeAreaInsets
                        let screenSize = window.bounds.size
                        circlePosition = CGPoint(
                            x: screenSize.width - safeArea.right - 44,
                            y: safeArea.top + 44
                        )
                    }
                }
            }
        }
    }
    
    private func findNearestCorner(predictedPosition: CGPoint, in size: CGSize) -> CGPoint {
        let margin: CGFloat = 44
        let safeMargin: CGFloat = 50
        
        let corners = [
            CGPoint(x: margin, y: safeMargin), // Top-left
            CGPoint(x: size.width - margin, y: safeMargin), // Top-right
            CGPoint(x: margin, y: size.height - safeMargin), // Bottom-left
            CGPoint(x: size.width - margin, y: size.height - safeMargin) // Bottom-right
        ]
        
        return corners.min { corner1, corner2 in
            distance(from: predictedPosition, to: corner1) < distance(from: predictedPosition, to: corner2)
        } ?? corners[0]
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
}

#Preview {
    CornerSnapView()
}
