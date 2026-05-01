//
//  DeviceActivityMonitorExtension.swift
//  TestingDeviceActivityMonitor
//
//  Created by Ricky Witherspoon on 4/11/25.
//

import DeviceActivity
import ManagedSettings
import UserNotifications
import FamilyControls

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    private let userNotificationCenter = UNUserNotificationCenter.current()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("🔄 Reapplying shields for new day")
        let tokens = loadActivitySelection()?.applicationTokens
        store.shield.applications = tokens
        
        Task {
            let content = UNMutableNotificationContent()
            content.title = "Blocking Apps"
            content.body = "intervalDidStart- We are blocking \(tokens?.count ?? -1) apps."
            content.sound = .default

            do {
                let request = UNNotificationRequest(identifier: "intervalDidStart", content: content, trigger: nil)
                try await userNotificationCenter.add(request)
                print("📨 Scheduled local notification for blocking")
            } catch {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        let tokensCount = loadActivitySelection()?.applicationTokens.count ?? -1

        print("🔓 Unblocking \(tokensCount) apps for: \(activity.rawValue)")
        store.shield.applications = nil
        
        Task {
            let content = UNMutableNotificationContent()
            content.title = "Unblocking Apps"
            content.body = "🔓 intervalDidEnd- Unblocking \(tokensCount) apps for: \(activity.rawValue)"
            content.sound = .default

            do {
                let request = UNNotificationRequest(identifier: "intervalDidEnd", content: content, trigger: nil)
                try await userNotificationCenter.add(request)
                print("📨 Scheduled local notification for unblocking")
            } catch {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func loadActivitySelection() -> FamilyActivitySelection? {
        guard let data = UserDefaults.shared.data(forKey: "SavedActivitySelection") else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}
