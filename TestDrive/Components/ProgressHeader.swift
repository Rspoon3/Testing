//
//  ProgressHeader.swift
//  TestDrive
//

import SwiftUI

/// Animated progress bar header for ranking sessions.
struct ProgressHeader: View {
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .animation(reduceMotion ? .none : .easeInOut, value: progress)

            Text("\(progress.formatted(.percent.precision(.fractionLength(0)))) Complete")
                .font(.caption)
                .foregroundStyle(.secondary)
                .contentTransition(reduceMotion ? .identity : .numericText(value: progress))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressHeader(progress: 0.0)
        ProgressHeader(progress: 0.25)
        ProgressHeader(progress: 0.5)
        ProgressHeader(progress: 0.75)
        ProgressHeader(progress: 1.0)
    }
    .padding()
}
