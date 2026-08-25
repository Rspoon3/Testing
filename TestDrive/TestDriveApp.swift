//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

@main
struct TestDriveApp: App {
    init() {
        // Disabled: forcing `canHandle` to `false` broke ALL drops, including the previously-
        // working custom payload — this controller turned out to be the only channel SwiftUI's
        // own `dropDestination` uses to relay accepted sessions, not a hostile interceptor in
        // front of it. See DragDestinationControllerSwizzle.swift's doc comment for details.
        // DragDestinationControllerSwizzle.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
