//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestDriveApp: App {
    private let stepGoalMonitor = StepGoalMonitor()
    @StateObject private var tabManager = TabManager()
    
    var body: some Scene {
        WindowGroup {
            AppTabNavigation()
                .environmentObject(tabManager)
                .task {
                    try? await stepGoalMonitor.requestNotifications()
                    stepGoalMonitor.startMonitoring()
                }
        }
    }
}
