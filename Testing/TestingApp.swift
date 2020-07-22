//
//  TestingApp.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/21/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

@main
struct TestingApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var persistentStore = PersistentStore.shared

    init(){
        ColorValueTransformer.register()
    }
    
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
