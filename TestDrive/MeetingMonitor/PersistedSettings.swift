//
//  PersistedSettings.swift
//  TestDrive
//

import AppKit
import Foundation
import SwiftUI

/// Persists user-configurable settings (lead, duration, color) across launches via UserDefaults.
///
/// The struct holds a reference to a `UserDefaults` instance so tests can inject an
/// in-memory suite (`UserDefaults(suiteName:)`).
struct PersistedSettings {
    private enum Key {
        static let warningLead = "MeetingMonitor.warningLead"
        static let warningDuration = "MeetingMonitor.warningDuration"
        static let glowColorRGBA = "MeetingMonitor.glowColorRGBA"
    }

    static let defaultWarningLead: TimeInterval = 60
    static let defaultWarningDuration: TimeInterval = 60
    static let defaultGlowColor: Color = .red

    private let defaults: UserDefaults

    /// Settings backed by `UserDefaults.standard`.
    static let live = PersistedSettings(defaults: .standard)

    // MARK: - Initializer

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - Public Helpers

    var warningLead: TimeInterval {
        get {
            let value = defaults.double(forKey: Key.warningLead)
            return value > 0 ? value : Self.defaultWarningLead
        }
        nonmutating set { defaults.set(newValue, forKey: Key.warningLead) }
    }

    var warningDuration: TimeInterval {
        get {
            let value = defaults.double(forKey: Key.warningDuration)
            return value > 0 ? value : Self.defaultWarningDuration
        }
        nonmutating set { defaults.set(newValue, forKey: Key.warningDuration) }
    }

    var glowColor: Color {
        get {
            guard let components = defaults.array(forKey: Key.glowColorRGBA) as? [Double],
                  components.count == 4 else {
                return Self.defaultGlowColor
            }
            return Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
        }
        nonmutating set {
            let ns = NSColor(newValue).usingColorSpace(.deviceRGB) ?? NSColor.systemRed
            let rgba: [Double] = [
                Double(ns.redComponent),
                Double(ns.greenComponent),
                Double(ns.blueComponent),
                Double(ns.alphaComponent)
            ]
            defaults.set(rgba, forKey: Key.glowColorRGBA)
        }
    }
}
