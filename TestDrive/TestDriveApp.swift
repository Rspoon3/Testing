//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

@main
struct TestDriveApp: App {
    @State private var monitor = MeetingMonitor.shared

    /// Stable id so the menu bar item (and anyone else) can call
    /// `openWindow(id:)` to bring the main window to front.
    static let mainWindowID = "main"

    var body: some Scene {
        Window("Meeting Border", id: Self.mainWindowID) {
            ContentView(monitor: monitor)
                .task { await monitor.start() }
        }
        .windowResizability(.contentSize)

        MenuBarExtra(
            isInserted: Binding(
                get: { monitor.showMenuBarItem },
                set: { monitor.showMenuBarItem = $0 }
            )
        ) {
            MenuBarContent(monitor: monitor)
        } label: {
            MenuBarLabel(countdown: monitor.menuBarCountdown)
        }
        .menuBarExtraStyle(.menu)
    }
}
