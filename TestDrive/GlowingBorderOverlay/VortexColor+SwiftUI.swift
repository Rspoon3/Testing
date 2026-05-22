//
//  VortexColor+SwiftUI.swift
//  TestDrive
//

import AppKit
import SwiftUI
import Vortex

extension VortexSystem.Color {
    /// Converts a `SwiftUI.Color` into Vortex's RGBA struct via `NSColor` so
    /// user-chosen colors in settings can be passed to a `VortexSystem.ColorMode`.
    init(swiftUI color: SwiftUI.Color) {
        let ns = NSColor(color).usingColorSpace(.deviceRGB) ?? .black
        self.init(
            red: Double(ns.redComponent),
            green: Double(ns.greenComponent),
            blue: Double(ns.blueComponent),
            opacity: Double(ns.alphaComponent)
        )
    }
}
