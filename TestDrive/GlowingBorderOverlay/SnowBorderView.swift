//
//  SnowBorderView.swift
//  TestDrive
//

import SwiftUI
import Vortex

/// Gently drifting snow flakes falling across the screen, tinted with the chosen color.
struct SnowBorderView: View {
    let color: Color

    // MARK: - Body

    var body: some View {
        VortexView(.snow) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .blur(radius: 5)
                .tag("circle")
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SnowBorderView(color: .white)
        .frame(width: 800, height: 500)
        .background(.black)
}
