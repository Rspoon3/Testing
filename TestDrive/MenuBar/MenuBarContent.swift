//
//  MenuBarContent.swift
//  TestDrive
//

import AppKit
import EventKit
import SwiftUI

/// The popup contents of the menu bar item — next meeting summary plus actions.
struct MenuBarContent: View {
    @Bindable var monitor: MeetingMonitor

    @Environment(\.openWindow) private var openWindow

    // MARK: - Body

    var body: some View {
        if let event = monitor.nextEvent {
            Text(event.title?.isEmpty == false ? event.title! : "Upcoming meeting")
                .font(.headline)
            Text("Starts \(event.startDate, format: .relative(presentation: .named, unitsStyle: .wide))")
            if let url = event.firstMeetingURL {
                Divider()
                Button("Join Meeting") {
                    NSWorkspace.shared.open(url)
                }
            }
        } else {
            Text("No upcoming meetings")
        }

        Divider()

        // The settings panel lives in the main window now (Settings tab), so
        // opening the main window covers what the old `SettingsLink` did.
        Button("Open Window…") {
            openWindow(id: TestDriveApp.mainWindowID)
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("Quit TestDrive") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
