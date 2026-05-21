//
//  PersistedSettingsTests.swift
//  TestDriveTests
//

import Foundation
import SwiftUI
import Testing
@testable import TestDrive

@MainActor
struct PersistedSettingsTests {

    @Test func returnsDefaultsForEmptySuite() {
        let settings = makeSettings()

        #expect(settings.warningLead == PersistedSettings.defaultWarningLead)
        #expect(settings.warningDuration == PersistedSettings.defaultWarningDuration)
    }

    @Test func roundTripsWarningLeadAndDuration() {
        let settings = makeSettings()

        settings.warningLead = 120
        settings.warningDuration = 45

        #expect(settings.warningLead == 120)
        #expect(settings.warningDuration == 45)
    }

    @Test func roundTripsShowMenuBarItem() {
        let settings = makeSettings()

        #expect(settings.showMenuBarItem == PersistedSettings.defaultShowMenuBarItem)

        settings.showMenuBarItem = true
        #expect(settings.showMenuBarItem == true)

        settings.showMenuBarItem = false
        #expect(settings.showMenuBarItem == false)
    }

    @Test func roundTripsBorderStyle() {
        let settings = makeSettings()

        #expect(settings.borderStyle == PersistedSettings.defaultBorderStyle)

        settings.borderStyle = .glow
        #expect(settings.borderStyle == .glow)

        settings.borderStyle = .colored
        #expect(settings.borderStyle == .colored)
    }

    @Test func roundTripsGlowColor() {
        let settings = makeSettings()

        settings.glowColor = .blue

        // Color → NSColor round-trip is RGB-component lossy, so compare via NSColor.
        let stored = NSColor(settings.glowColor).usingColorSpace(.deviceRGB)
        let expected = NSColor(Color.blue).usingColorSpace(.deviceRGB)
        #expect(stored?.redComponent == expected?.redComponent)
        #expect(stored?.greenComponent == expected?.greenComponent)
        #expect(stored?.blueComponent == expected?.blueComponent)
    }

    // MARK: - Helpers

    private func makeSettings() -> PersistedSettings {
        let suite = "PersistedSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return PersistedSettings(defaults: defaults)
    }
}
