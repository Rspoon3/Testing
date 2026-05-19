//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

@main
struct TestDriveApp: App {
    @State private var monitor = MeetingMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView(monitor: monitor)
                .task { await monitor.start() }
        }
        .windowResizability(.contentSize)

        Settings {
            DebugSettingsView(monitor: monitor)
        }
    }
}
