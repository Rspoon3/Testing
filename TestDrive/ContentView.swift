//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Foundation

enum ScaleMode: String, CaseIterable {
    case scalesUp = "Scales Up"
    case scalesDown = "Scales Down"
    case noScaling = "No Scaling"
}

struct ContentView: View {
    @AppStorage("stiffness") private var stiffness: Double = 0.15
    @AppStorage("dampingFraction") private var dampingFraction: Double = 0.6
    @AppStorage("scaleMode") private var scaleMode: ScaleMode = .scalesDown
    @State private var buttonOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var distanceFromCenter: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Stiffness: \(stiffness.formatted())")
                Slider(value: $stiffness, in: 0...3)
                    .padding([.horizontal, .bottom])
                
                Text("Damping: \(dampingFraction.formatted())")
                Slider(value: $dampingFraction, in: 0...3)
                    .padding([.horizontal, .bottom])
                
                Picker("Scale Mode", selection: $scaleMode) {
                    ForEach(ScaleMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .bottom])
                
                Spacer()
                
                Image(systemName: "star.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .padding([.trailing, .bottom])
                    .foregroundStyle(.white, .blue)
                    .offset(buttonOffset)
                    .scaleEffect({
                        switch scaleMode {
                        case .scalesUp:
                            return 1 + distanceFromCenter * 0.01
                        case .scalesDown:
                            return 1 - distanceFromCenter * 0.01
                        case .noScaling:
                            return 1
                        }
                    }())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let rubberBandLimit: CGFloat = 80
                                
                                let inputDistance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                                
                                // Rubber band formula: creates diminishing returns as you pull further
                                let rubberBandDistance = rubberBandLimit * (1 - exp(-inputDistance * stiffness / rubberBandLimit))
                                
                                distanceFromCenter = rubberBandDistance
                                
                                if inputDistance > 0 {
                                    let ratio = rubberBandDistance / inputDistance
                                    buttonOffset = CGSize(
                                        width: value.translation.width * ratio,
                                        height: value.translation.height * ratio
                                    )
                                } else {
                                    buttonOffset = .zero
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                withAnimation(.spring(response: 0.4, dampingFraction: dampingFraction)) {
                                    buttonOffset = .zero
                                    distanceFromCenter = 0
                                }
                            }
                    )
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
