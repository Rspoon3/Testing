//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

/// The root tab view of the app.
struct ContentView: View {

    // MARK: - Body

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }

            Tab("Currency", systemImage: "dollarsign.circle") {
                CurrencyView()
            }

            Tab("Optional", systemImage: "questionmark.circle") {
                OptionalCurrencyView()
            }

            Tab("String", systemImage: "textformat") {
                StringCurrencyView()
            }
        }
    }
}

#Preview {
    ContentView()
}
