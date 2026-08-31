//
//  BadgeCanvas.swift
//  TestDrive
//

import SwiftUI

/// The size the badge artwork is laid out at.
///
/// The faces use fixed point sizes for the symbol and the engraved text, which is
/// what the flat tabs want — they draw at roughly this size on screen. But it means
/// the artwork does not scale with its frame: rendering the same view into a 1024px
/// texture made every glyph half as large relative to the disc.
///
/// So layout always happens at this canvas size and the result is scaled to the
/// requested output. Texture resolution and artwork proportions stay independent.
let badgeCanvasSize: CGFloat = 300

extension View {

    // MARK: - Public Helpers

    /// Lays this view out on the badge design canvas and scales it to `size`.
    /// - Parameter size: The output edge length, in points or pixels.
    /// - Returns: The view, scaled.
    func badgeCanvas(scaledTo size: CGFloat) -> some View {
        frame(width: badgeCanvasSize, height: badgeCanvasSize)
            .scaleEffect(size / badgeCanvasSize)
            .frame(width: size, height: size)
    }
}
