//
//  MeetingToastView.swift
//  TestDrive
//

import SwiftUI

/// Floating banner showing the upcoming meeting with optional Join + Dismiss controls.
struct MeetingToastView: View {
    let content: MeetingToastContent
    let onJoin: (URL) -> Void
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "video.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(content.title)
                    .font(.headline)
                    .lineLimit(1)
                Subtitle()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let url = content.joinURL {
                Button {
                    onJoin(url)
                } label: {
                    Label("Join", systemImage: "arrow.up.forward.app.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .accessibilityIdentifier("toast.join")
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(6)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Dismiss")
            .accessibilityIdentifier("toast.dismiss")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        // Corner rounding is applied to the hosting view's layer in
        // `MeetingToastController` so the round propagates to whatever AppKit
        // view the SwiftUI content actually sits inside, not just the SwiftUI
        // bounds.
        .accessibilityIdentifier("toast.root")
    }

    // MARK: - Private Views

    @ViewBuilder
    private func Subtitle() -> some View {
        if let start = content.startsAt {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(subtitle(for: start, now: context.date))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Private Helpers

    /// Returns "Starts in 0:47", "Starting now", or "Started 0:12 ago" based on the offset to `start`.
    private func subtitle(for start: Date, now: Date) -> String {
        let remaining = start.timeIntervalSince(now)
        let elapsed = -remaining
        if remaining >= 1 {
            return "Starts in \(Duration.seconds(remaining).formattedCountdown())"
        }
        if abs(remaining) < 1 {
            return "Starting now"
        }
        return "Started \(Duration.seconds(elapsed).formattedCountdown()) ago"
    }
}

#Preview("With Join") {
    MeetingToastView(
        content: MeetingToastContent(
            title: "Mobile Weekly Sync",
            joinURL: URL(string: "https://fetchrewards.zoom.us/j/95176772193"),
            startsAt: Date().addingTimeInterval(47)
        ),
        onJoin: { _ in },
        onDismiss: { }
    )
    .padding()
    .frame(width: 480)
}

#Preview("No URL") {
    MeetingToastView(
        content: MeetingToastContent(
            title: "Quiet block",
            joinURL: nil,
            startsAt: Date().addingTimeInterval(120)
        ),
        onJoin: { _ in },
        onDismiss: { }
    )
    .padding()
    .frame(width: 480)
}
