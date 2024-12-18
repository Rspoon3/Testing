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
            if let heartRate = heartRateManager.heartRate {
                Text(heartRate.value.formatted())
                    .contentTransition(.numericText(value: Double(heartRate.value)))
                
                Text("Last Update: \(heartRate.lastUpdate.formatted())")
                    .foregroundStyle(.secondary)
                Text("Start Date: \(heartRate.startDate.formatted())")
                    .foregroundStyle(.secondary)
                Text("End Date: \(heartRate.endDate.formatted())")
                    .foregroundStyle(.secondary)
            }
            
            contentView
        }
        .task {
            await heartRateManager.requestAuthorization()
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
                power2: viewModel.power2,
                distance: viewModel.distance,
                elapsedTime: viewModel.elapsedTime,
                speed: viewModel.speed,
                heartRate: heartRateManager.heartRate?.value
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
