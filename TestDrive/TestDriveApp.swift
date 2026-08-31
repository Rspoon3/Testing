//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

@main
struct TestDriveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Debug-only, launch-argument gated. See `ArtworkExporter`.
                    if ArtworkExporter.isRequested {
                        ArtworkExporter.exportAll()
                    }
                }
        }
    }
}
