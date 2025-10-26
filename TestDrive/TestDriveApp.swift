//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI
import UserNotifications

@main
struct TestDriveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if DEBUG
                .task {
                    await requestNotificationPermissions()
                }
                #endif
        }
    }

    #if DEBUG
    private func requestNotificationPermissions() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            print("Failed to request notification permissions: \(error)")
        }
    }
    #endif
}
