//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestDriveApp: App {
    let loginService = KudoboardLoginService()
    
    var body: some Scene {
        WindowGroup {
            Button("Go") {
                Task {
                    try await send()
                }
            }
//            .task {
//                try? await send()
//            }
        }
    }
    
    func send() async throws {
        // Define the board ID and message to post
        let boardID = "BDk2ACtk"
        let message = "Nice work!"
        
        let poster = KudoboardPoster(loginService: loginService)
        try await poster.postKudo(to: boardID, messageHTML: message)
    }
}
