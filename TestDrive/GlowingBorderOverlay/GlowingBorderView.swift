//
//  GlowingBorderView.swift
//  TestDrive
//

import SwiftUI

/// A pulsing, glowing border that fills its container in the supplied color.
///
/// Intended to be rendered inside a transparent, click-through window that
/// covers an entire screen — the layered shadows create a glow effect that
/// blooms inward from the screen edges.
struct GlowingBorderView: View {
    let color: Color

    private let strokeWidth: CGFloat = 8
    private let pulsePeriod: TimeInterval = 2.2

    // MARK: - Body

    var body: some View {
        TimelineView(.animation) { context in
            let phase = pulsePhase(at: context.date)
            Rectangle()
                .strokeBorder(color, lineWidth: strokeWidth)
                .shadow(color: color, radius: 18 + 10 * phase)
                .shadow(color: color.opacity(0.8), radius: 38 + 18 * phase)
                .shadow(color: color.opacity(0.55), radius: 60 + 30 * phase)
                .opacity(0.75 + 0.25 * phase)
        }
        .ignoresSafeArea()
    }

    // MARK: - Private Helpers

    /// Returns a smooth 0…1 pulse value derived from the supplied date.
    private func pulsePhase(at date: Date) -> Double {
        let t = date.timeIntervalSinceReferenceDate
        return (sin(t * 2 * .pi / pulsePeriod) + 1) / 2
    }
}

#Preview {
    GlowingBorderView(color: .red)
        .frame(width: 800, height: 500)
        .background(.black)
}
