//
//  RainBorderView.swift
//  TestDrive
//

import SwiftUI
import Vortex

/// Streaks of rain falling top-to-bottom, tinted with the chosen color.
struct RainBorderView: View {
    let color: Color

    // MARK: - Body

    var body: some View {
        VortexView(.rain) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .tag("circle")
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RainBorderView(color: .blue)
        .frame(width: 800, height: 500)
        .background(.black)
}
