//
//  ConfettiView.swift
//  Testing (iOS)
//
//  Created by Ricky on 11/30/24.
//

import SwiftUI
import Vortex

struct ConfettiView: View {
    let id: UUID?
    
    var body: some View {
        VortexViewReader { proxy in
            VortexView(
                VortexSystem(
                    tags: ["square", "circle"],
                    position: [0.5,0.25],
                    birthRate: 0,
                    lifespan: 4,
                    speed: 0.5,
                    speedVariation: 0.5,
                    angleRange: .degrees(90),
                    acceleration: [0, 1],
                    angularSpeedVariation: [4, 4, 4],
                    colors: .random(.white, .red, .green, .blue, .pink, .orange, .cyan),
                    size: 0.5,
                    sizeVariation: 0.5
                )
            ) {
                Rectangle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .tag("square")
                
                Circle()
                    .fill(.white)
                    .frame(width: 16)
                    .tag("circle")
            }
            .onChange(of: id) { _, _ in
                proxy.burst()
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .top)
    }
}
