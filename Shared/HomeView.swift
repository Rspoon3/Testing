//
//  EchelonDeviceManager.swift
//  Testing
//
//  Created by Ricky on 12/16/24.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isConnected {
                VStack {
                    Text("Echelon Bike Metrics")
                        .font(.title2)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            MetricTile(label: "Cadence", value: "\(viewModel.cadence) RPM")
                            MetricTile(label: "Resistance", value: "\(viewModel.resistance)")
                            MetricTile(label: "Power", value: "\(viewModel.power) W")
                            MetricTile(label: "Distance", value: "\(viewModel.distance) M")
                            MetricTile(label: "Elapsed Time", value: "\(viewModel.elapsedTime) M")
                        }
                    }
                    .contentMargins(16, for: .scrollContent)
                }
            } else {
                Text("Scanning for Echelon Bike...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .onAppear {
            viewModel.startScanning()
        }
    }
}
