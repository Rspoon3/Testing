//
//  TestDriveAppShortcuts.swift
//  TestDrive
//

import AppIntents

/// Registers our `AppIntent`s with the system so they're discoverable in
/// Shortcuts, Spotlight, and Siri even when the app isn't running.
///
/// Each `AppShortcut` ties an intent to one or more invocation phrases (the
/// `\(.applicationName)` placeholder is required for Siri dispatch), a short
/// title for the Shortcuts library, and an SF Symbol for the listing.
struct TestDriveAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerOverlayIntent(),
            phrases: [
                "Trigger \(.applicationName) overlay",
                "Show \(.applicationName) border",
                "Fire \(.applicationName)"
            ],
            shortTitle: "Trigger Overlay",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: HideOverlayIntent(),
            phrases: [
                "Hide \(.applicationName) overlay",
                "Dismiss \(.applicationName) border"
            ],
            shortTitle: "Hide Overlay",
            systemImageName: "xmark.circle"
        )

        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start \(.applicationName) timer",
                "Start \(.applicationName) countdown"
            ],
            shortTitle: "Start Timer",
            systemImageName: "play.circle"
        )

        AppShortcut(
            intent: CancelTimerIntent(),
            phrases: [
                "Cancel \(.applicationName) timer",
                "Stop \(.applicationName) timer"
            ],
            shortTitle: "Cancel Timer",
            systemImageName: "stop.circle"
        )

        AppShortcut(
            intent: SetBorderStyleIntent(),
            phrases: [
                "Set \(.applicationName) border style",
                "Change \(.applicationName) overlay style"
            ],
            shortTitle: "Set Border Style",
            systemImageName: "paintpalette"
        )

        AppShortcut(
            intent: SetWarningLeadIntent(),
            phrases: [
                "Set \(.applicationName) warning lead time"
            ],
            shortTitle: "Set Warning Lead",
            systemImageName: "alarm"
        )

        AppShortcut(
            intent: SetOverlayDurationIntent(),
            phrases: [
                "Set \(.applicationName) overlay duration"
            ],
            shortTitle: "Set Overlay Duration",
            systemImageName: "clock"
        )

        AppShortcut(
            intent: SetTimerDurationIntent(),
            phrases: [
                "Set \(.applicationName) timer duration"
            ],
            shortTitle: "Set Timer Duration",
            systemImageName: "timer"
        )
    }
}
