//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    var body: some Scene {
        WindowGroup {
//            OrderConfirmationView(person: .ricky)
//            PurchaseScreen(person: .ricky)
            PersonDetailsView(person: .ricky)
//            ContentView()
        }
    }
}
