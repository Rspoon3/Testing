//
//  TestingApp.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/21/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

class AppDelegateAdaptor: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PersistentStore.shared.deleteEverythingForDebug()
        return true
    }
}

@main
struct TestingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegateAdaptor.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var persistentStore = PersistentStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentStore.context)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                print("\(#function) REPORTS - App change of scenePhase to ACTIVE")
            case .inactive:
                print("\(#function) REPORTS - App change of scenePhase to INACTIVE")
            case .background:
                print("\(#function) REPORTS - App change of scenePhase to BACKGROUND")
                persistentStore.saveContext()
            @unknown default:
                fatalError("\(#function) REPORTS - fatal error in switch statement for .onChange modifier")
            }
        }
    }
}
