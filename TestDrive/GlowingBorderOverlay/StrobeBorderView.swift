//
//  StrobeBorderView.swift
//  TestDrive
//

import SwiftUI

/// Flashes the entire screen white in the Morse-code SOS pattern (`... --- ...`).
///
/// Built around standard Morse timing relative to one "unit":
/// * dot = 1 unit
/// * dash = 3 units
/// * intra-letter gap = 1 unit
/// * inter-letter gap = 3 units
/// * end-of-message pause = 7 units
///
/// A unit of 180ms keeps the rhythm urgent without making the dots and
/// dashes blur together.
struct StrobeBorderView: View {
    @State private var isOn = false

    /// Duration of one Morse unit in seconds.
    private static let unit: TimeInterval = 0.18

    private static let sosPattern: [PatternStep] = [
        // S — ...
        .on(1), .off(1), .on(1), .off(1), .on(1),
        // inter-letter gap (already had a 1u trailing-on, want 3u total off → add 2u? No:
        // an intra-letter "off(1)" sits between dots; the gap *after* a letter is just 3u total).
        .off(3),
        // O — ---
        .on(3), .off(1), .on(3), .off(1), .on(3),
        .off(3),
        // S — ...
        .on(1), .off(1), .on(1), .off(1), .on(1),
        // long pause before the next SOS so the pattern reads as repeated
        // distress calls rather than a continuous strobe.
        .off(7)
    ]

    // MARK: - Body

    var body: some View {
        Color.white
            .opacity(isOn ? 1 : 0)
            .ignoresSafeArea()
            .task { await runPattern() }
    }

    // MARK: - Private Helpers

    /// Walks the SOS pattern forever, sleeping for each segment's duration.
    private func runPattern() async {
        while !Task.isCancelled {
            for step in Self.sosPattern {
                guard !Task.isCancelled else { return }
                isOn = step.isOn
                let ms = Int((step.units * Self.unit) * 1000)
                try? await Task.sleep(for: .milliseconds(ms))
            }
        }
    }
}

/// One on/off segment of the strobe pattern, sized in Morse units.
private struct PatternStep {
    let isOn: Bool
    let units: Double

    static func on(_ units: Double) -> PatternStep { .init(isOn: true, units: units) }
    static func off(_ units: Double) -> PatternStep { .init(isOn: false, units: units) }
}

#Preview {
    StrobeBorderView()
        .frame(width: 600, height: 400)
        .background(.black)
}
