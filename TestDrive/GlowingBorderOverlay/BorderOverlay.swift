//
//  BorderOverlay.swift
//  TestDrive
//

import SwiftUI

/// Dispatches to the concrete border view for a given ``BorderStyle``.
///
/// Sits between the controller and the per-style views so adding a new
/// ``BorderStyle`` case only requires extending the switch below.
struct BorderOverlay: View {
    let style: BorderStyle
    let color: Color

    // MARK: - Body

    var body: some View {
        switch style {
        case .colored:
            GlowingBorderView(color: color)
        case .glow:
            SiriGlowBorderView()
        }
    }
}
