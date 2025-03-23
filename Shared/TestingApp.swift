//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    let loginService = KudoboardLoginService()
    
    var body: some Scene {
        WindowGroup {
            Button("Go") {
                Task {
                    await send()
                }
            }
            .task {
                await send()
            }
        }
    }
    
    func send() async {
            // Define the board ID and message to post
            let boardID = "BDk2ACtk"
            let message = "<p>Shes back with food!</p>"
            
            // Main execution function using async/await
            do {
                // Step 1: Get login page
                print("Getting login page...")
                try await loginService.getLoginPage()
                
                // Step 2: Login with credentials
                print("Logging in...")
                try await loginService.login(email: "richardwitherspoon3@gmail.com", password: "setquc-hipSa3-pykwad")
                print("Successfully logged in.")
                
                // Step 3: Visit the board page to get a fresh CSRF token
                print("Visiting board page...")
                try await loginService.visitBoardPage(boardID: boardID)
                print("Successfully visited board page and refreshed CSRF token.")
                
                // Step 4: Post the kudo
                print("Posting kudo...")
                try await loginService.postKudo(to: boardID, messageHTML: message)
                print("🎉 Post submitted successfully!")
            } catch KudoboardError.networkError(let message) {
                print("Network error: \(message)")
            } catch KudoboardError.jsonParsingError(let message) {
                print("JSON parsing error: \(message)")
            } catch KudoboardError.loginFailed(let message) {
                print("Login failed: \(message)")
            } catch KudoboardError.csrfTokenNotFound {
                print("CSRF token not found")
            } catch KudoboardError.httpError(let code, let message) {
                print("HTTP error \(code): \(message)")
            } catch {
                print("Unexpected error: \(error.localizedDescription)")
            }
    }
}
