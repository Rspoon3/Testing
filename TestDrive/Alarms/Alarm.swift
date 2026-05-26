//
//  Alarm.swift
//  TestDrive
//

import AppKit
import Foundation
import SwiftUI

/// A user-defined alarm that fires the overlay at a specific time of day.
///
/// `weekdays.isEmpty` means a one-shot alarm — it fires once and then sets
/// itself to `isEnabled = false`. With weekdays selected it fires every
/// matching day. Each alarm carries its own border style / color / fireworks
/// mode so different alarms can produce different visual effects.
struct Alarm: Identifiable, Codable, Hashable {
    let id: UUID
    var hour: Int                       // 0…23
    var minute: Int                     // 0…59
    var weekdays: Set<Weekday>
    var label: String
    var borderStyle: BorderStyle
    /// RGBA components in deviceRGB space — Color isn't Codable so we store
    /// the bridge and convert on access via `glowColor`.
    var glowColorRGBA: [Double]
    var fireworksColorMode: FireworksColorMode
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        hour: Int = 9,
        minute: Int = 0,
        weekdays: Set<Weekday> = [],
        label: String = "",
        borderStyle: BorderStyle = .colored,
        glowColor: Color = .red,
        fireworksColorMode: FireworksColorMode = .fixed,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.label = label
        self.borderStyle = borderStyle
        self.glowColorRGBA = Self.rgba(from: glowColor)
        self.fireworksColorMode = fireworksColorMode
        self.isEnabled = isEnabled
    }

    /// SwiftUI `Color` bridge backed by the stored RGBA components.
    var glowColor: Color {
        get {
            guard glowColorRGBA.count == 4 else { return .red }
            return Color(
                red: glowColorRGBA[0],
                green: glowColorRGBA[1],
                blue: glowColorRGBA[2],
                opacity: glowColorRGBA[3]
            )
        }
        set { glowColorRGBA = Self.rgba(from: newValue) }
    }

    /// `true` when no weekdays are selected — alarm fires the first time the
    /// clock matches, then disables itself.
    var isOneShot: Bool { weekdays.isEmpty }

    // MARK: - Private Helpers

    private static func rgba(from color: Color) -> [Double] {
        let ns = NSColor(color).usingColorSpace(.deviceRGB) ?? .red
        return [
            Double(ns.redComponent),
            Double(ns.greenComponent),
            Double(ns.blueComponent),
            Double(ns.alphaComponent)
        ]
    }
}
