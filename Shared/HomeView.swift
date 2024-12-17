//
//  EchelonDeviceManager.swift
//  Testing
//
//  Created by Ricky on 12/16/24.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var heartRateManager = HeartRateManager()

    var body: some View {
        VStack {
            Text(heartRateManager.heartRate.formatted())
                .task {
                    await heartRateManager.requestAuthorization()
                }
            if let lastUpdate = heartRateManager.lastUpdate {
                Text("Last Update: \(lastUpdate.formatted())")
                    .foregroundStyle(.secondary)
            }
            
            contentView
        }
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isConnected {
            MetricContentView(
                cadence: viewModel.cadence,
                resistance: viewModel.resistance,
                power: viewModel.power,
                distance: viewModel.distance,
                elapsedTime: viewModel.elapsedTime,
                speed: viewModel.speed,
                heartRate: heartRateManager.heartRate
            )
        } else {
            Text("Scanning for Echelon Bike...")
                .foregroundColor(.gray)
                .padding()
                .onAppear {
                    viewModel.startScanning()
                }
        }
    }
}
