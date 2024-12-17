//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

// MARK: - SwiftUI Main View
struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if bluetoothManager.isConnected {
                    Text("Echelon Smart Connect Bike")
                        .font(.headline)
                    Text("Cadence: \(bluetoothManager.cadence, specifier: "%.0f") RPM")
                    Text("Resistance: \(bluetoothManager.resistance)")
                    Text("Power: \(bluetoothManager.power, specifier: "%.1f") W")
                } else {
                    Text("Searching for Echelon Bike...")
                        .foregroundColor(.gray)
                }
            }
            .font(.title2)
            .padding()
            .navigationTitle("Bike Metrics")
            .onAppear {
                bluetoothManager.startScanning()
            }
        }
    }
}

#Preview {
    ContentView()
}
