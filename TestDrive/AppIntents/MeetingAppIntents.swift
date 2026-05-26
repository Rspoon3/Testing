//
//  MeetingAppIntents.swift
//  TestDrive
//

import AppIntents
import Foundation

// MARK: - BorderStyle as a Shortcuts-pickable enum

extension BorderStyle: AppEnum {
    // Static properties default to `@MainActor` under this project's actor
    // isolation settings, which makes the protocol conformance carry main-actor
    // isolation — and that conflicts with `AppEnum`'s `Self: Sendable`
    // requirement. Marking them `nonisolated` keeps the conformance pure.
    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Border Style")
    }

    nonisolated static var caseDisplayRepresentations: [BorderStyle: DisplayRepresentation] {
        [
            .colored: "Colored border",
            .glow: "Glow",
            .boids: "Birds",
            .confetti: "Confetti",
            .fireflies: "Fireflies",
            .rain: "Rain",
            .snow: "Snow",
            .magic: "Magic",
            .fireworks: "Fireworks",
            .fire: "Fire",
            .smoke: "Smoke",
            .splash: "Splash",
            .bouncyBalls: "Bouncy balls",
            .virus: "90s Virus",
            .strobe: "Strobe (SOS)",
            .slime: "Slime",
            .random: "Random"
        ]
    }
}

// MARK: - Overlay control intents

struct TriggerOverlayIntent: AppIntent {
    static var title: LocalizedStringResource = "Trigger Border Overlay"
    static var description = IntentDescription("Shows the meeting border overlay immediately, using the currently selected border style.")

    @MainActor
    func perform() async throws -> some IntentResult {
        MeetingMonitor.shared.triggerOverlayForTesting()
        return .result()
    }
}

struct HideOverlayIntent: AppIntent {
    static var title: LocalizedStringResource = "Hide Border Overlay"
    static var description = IntentDescription("Dismisses the meeting border overlay if it's currently visible.")

    @MainActor
    func perform() async throws -> some IntentResult {
        MeetingMonitor.shared.dismissOverlay()
        return .result()
    }
}

// MARK: - Appearance

struct SetBorderStyleIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Border Style"
    static var description = IntentDescription("Picks which visual effect plays when the overlay triggers.")

    @Parameter(title: "Style")
    var style: BorderStyle

    @MainActor
    func perform() async throws -> some IntentResult {
        MeetingMonitor.shared.borderStyle = style
        return .result()
    }
}

// MARK: - Timing

struct SetWarningLeadIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Meeting Warning Lead Time"
    static var description = IntentDescription("Sets how many seconds before each meeting the overlay appears.")

    @Parameter(title: "Seconds", default: 60, inclusiveRange: (5, 600))
    var seconds: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        MeetingMonitor.shared.warningLead = TimeInterval(seconds)
        return .result()
    }
}

struct SetOverlayDurationIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Overlay Duration"
    static var description = IntentDescription("Sets how long the overlay stays on screen each time it fires.")

    @Parameter(title: "Seconds", default: 60, inclusiveRange: (5, 300))
    var seconds: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        MeetingMonitor.shared.warningDuration = TimeInterval(seconds)
        return .result()
    }
}

struct SetTimerDurationIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Countdown Timer Duration"
    static var description = IntentDescription("Sets the duration of the countdown timer that triggers the overlay when started.")

    @Parameter(title: "Seconds", default: 300, inclusiveRange: (5, 3600))
    var seconds: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        MeetingMonitor.shared.timerDuration = TimeInterval(seconds)
        return .result()
    }
}

// MARK: - Timer control

struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Countdown Timer"
    static var description = IntentDescription("Starts the countdown timer. When it expires, the overlay fires using the current border style.")

    @MainActor
    func perform() async throws -> some IntentResult {
        MeetingMonitor.shared.startTimer()
        return .result()
    }
}

struct CancelTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel Countdown Timer"
    static var description = IntentDescription("Cancels a running countdown timer without firing the overlay.")

    @MainActor
    func perform() async throws -> some IntentResult {
        MeetingMonitor.shared.cancelTimer()
        return .result()
    }
}
