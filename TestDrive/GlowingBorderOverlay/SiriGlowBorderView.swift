//
//  SiriGlowBorderView.swift
//  TestDrive
//

import SwiftUI

/// A Siri-style multicolored mesh-gradient glow drawn at the screen edges.
///
/// Composes a full-screen ``MeshGradientView`` with a stroked, blurred
/// ``AnimatedRectangle`` mask so only the wavy, breathing perimeter is visible.
/// Adapted from https://github.com/metasidd/Prototype-Siri-Screen-Animation
struct SiriGlowBorderView: View {
    @State private var maskTimer: Float = 0.0
    @State private var gradientSpeed: Float = 0.03

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            MeshGradientView(maskTimer: $maskTimer, gradientSpeed: $gradientSpeed)
                .scaleEffect(1.3) // avoid clipping at the edges
                .mask {
                    AnimatedRectangle(
                        size: geometry.size,
                        cornerRadius: 48,
                        t: CGFloat(maskTimer)
                    )
                    .stroke(Color.white, lineWidth: 60)
                    .blur(radius: 24)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SiriGlowBorderView()
        .frame(width: 800, height: 500)
        .background(.black)
}
