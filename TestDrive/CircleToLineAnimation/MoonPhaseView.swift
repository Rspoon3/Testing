//
//  MoonPhaseView.swift
//  TestDrive
//
//  Created by Claude Code
//

import SwiftUI

/// A view representing a moon phase with customizable fill and color.
struct MoonPhaseView: View {
    private let fillPercentage: Double
    private let color: Color
    private let size: CGFloat

    // MARK: - Initializer

    /// Creates a moon phase view.
    /// - Parameters:
    ///   - fillPercentage: The percentage of the moon that is filled (0.0 to 1.0).
    ///   - color: The color of the filled portion.
    ///   - size: The size of the moon view.
    init(fillPercentage: Double, color: Color, size: CGFloat = 20) {
        self.fillPercentage = fillPercentage
        self.color = color
        self.size = size
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))

            Circle()
                .trim(from: 0, to: fillPercentage)
                .fill(color)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 10) {
        MoonPhaseView(fillPercentage: 0, color: .purple)
        MoonPhaseView(fillPercentage: 0.25, color: .red)
        MoonPhaseView(fillPercentage: 0.5, color: .pink)
        MoonPhaseView(fillPercentage: 0.75, color: .orange)
        MoonPhaseView(fillPercentage: 1.0, color: .yellow)
    }
    .padding()
    .background(.black)
}
