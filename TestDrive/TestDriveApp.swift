//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import Dependencies
import SwiftUI

enum AppConfig {
    static let enableTimers = false
}

@main
struct TestDriveApp: App {
    init() {
        prepareDependencies {
            try! $0.bootstrapDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
