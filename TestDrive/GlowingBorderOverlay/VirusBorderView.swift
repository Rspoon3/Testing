//
//  VirusBorderView.swift
//  TestDrive
//

import SwiftUI

/// A "90s virus" overlay — scatters animated popup windows across the screen,
/// each pulled from the unique-content catalog in ``PopupSpec``.
///
/// Maintains up to ~6 popups at a time. Every 0.4–1.2 seconds a new popup
/// appears at a random position with a random spec; once the cap is reached
/// the oldest popup is dropped to make room. Spec selection avoids picking
/// any spec that's already on screen so duplicates rarely overlap.
struct VirusBorderView: View {

    private struct PopupInstance: Identifiable {
        let id = UUID()
        let spec: PopupSpec
        let position: CGPoint
        let width: CGFloat
        let scale: CGFloat
    }

    private static let maxOnScreen = 12

    @State private var popups: [PopupInstance] = []

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(popups) { popup in
                    VirusPopup(spec: popup.spec, width: popup.width, scale: popup.scale)
                        .position(popup.position)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .ignoresSafeArea()
            .task { await drivePopupShow(in: proxy.size) }
        }
    }

    // MARK: - Private Helpers

    /// Long-running task that seeds an initial batch of popups and then
    /// keeps spawning and retiring them until the view is removed.
    private func drivePopupShow(in size: CGSize) async {
        // Seed a chunk so the screen looks "infected" right away.
        for _ in 0..<5 {
            spawn(in: size)
            try? await Task.sleep(for: .milliseconds(100))
        }
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(.random(in: 250...900)))
            withAnimation(.easeOut(duration: 0.25)) {
                spawn(in: size)
                if popups.count > Self.maxOnScreen {
                    popups.removeFirst()
                }
            }
        }
    }

    /// Picks a spec not already on screen (if possible) and drops it at a
    /// random position. Each popup gets its own width + scale for variety,
    /// and the position bounds are derived per-popup so big dialogs aren't
    /// allowed to spawn where their corners would clip off the screen.
    @MainActor
    private func spawn(in size: CGSize) {
        let inUse = Set(popups.map(\.spec.id))
        let unused = PopupSpec.catalog.filter { !inUse.contains($0.id) }
        let pool = unused.isEmpty ? PopupSpec.catalog : unused
        guard let spec = pool.randomElement() else { return }

        let width = CGFloat.random(in: 230...380)
        let scale = CGFloat.random(in: 0.85...1.2)
        // Approximate the popup's footprint: an extra-tall buffer covers the
        // unknown content height. Slightly over-conservative, which is fine.
        let halfW = (width * scale) / 2
        let halfH = (260 * scale) / 2

        guard size.width > 2 * halfW + 20,
              size.height > 2 * halfH + 20
        else { return }

        let popup = PopupInstance(
            spec: spec,
            position: CGPoint(
                x: .random(in: halfW...(size.width - halfW)),
                y: .random(in: halfH...(size.height - halfH))
            ),
            width: width,
            scale: scale
        )
        popups.append(popup)
    }
}

#Preview {
    VirusBorderView()
        .frame(width: 1200, height: 800)
        .background(Color(white: 0.2))
}
