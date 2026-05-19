//
//  MenuBarLabel.swift
//  TestDrive
//

import SwiftUI

/// The compact label shown in the macOS menu bar — calendar icon plus an
/// optional pre-formatted countdown string to the next meeting.
///
/// The countdown is rendered as static text. `Text(_:style: .timer)` was tried
/// first but `MenuBarExtra` rasterizes its label into the `NSStatusItem` image,
/// and the timer style drives that rasterization continuously, pinning CPU and
/// leaking memory. The countdown is instead updated once per second by
/// `MeetingMonitor`.
struct MenuBarLabel: View {
    let countdown: String?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
            if let countdown {
                Text(countdown)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    MenuBarLabel(countdown: "2:05")
        .padding()
}
