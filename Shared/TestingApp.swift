//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var socketManager = SocketIOManager.shared
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                socketManager.establishConnection()
            case .inactive:
                print("\(#function) REPORTS - App change of scenePhase to INACTIVE")
            case .background:
                socketManager.closeConnection()
            @unknown default:
                fatalError("\(#function) REPORTS - fatal error in switch statement for .onChange modifier")
            }
        }
    }
}
