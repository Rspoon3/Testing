//
//  HomeViewModel.swift
//  Testing
//
//  Created by Ricky on 12/17/24.
//

import Foundation
import CoreBluetooth

@Observable
@MainActor
final class HomeViewModel {
    private let bluetoothManager: any BluetoothManagerProtocol
    private(set) var isConnected = false
    private(set) var cadence: Int = 0
    private(set) var resistance: Int = 0
    private(set) var distance: Double = 0
    private(set) var power: Int = 0
    private(set) var power2: Int = 0
    private(set) var speed: Int = 0
    private(set) var elapsedTime: String = "00:00"
    private(set) var discoveredPeripherals: [Peripheral] = []
    private(set) var historicalMetrics: [SavedMetrics] = []

    // Timer
    var isRunning = true
    var startTime = Date()
    var elapsedTime2: TimeInterval = 0
    
    // MARK: - Initializer
    
    init(bluetoothManager: any BluetoothManagerProtocol = MockBluetoothManager()) {
        self.bluetoothManager = bluetoothManager
        self.bluetoothManager.delegate = self
    }
    
    // MARK: - Public
    
    func startScanning() {
        bluetoothManager.startScanning()
    }
    
    // MARK: - Private Helpers
    
    private func calculatePower(cadence: Int, resistance: Int) -> Int {
        // https://github.com/ptx2/gymnasticon/issues/27
        let _power2 = pow(1.090112, Double(resistance)) * pow(1.015343, Double(cadence)) * 7.228958
        power2 = Int(_power2)
        // Simple power estimation: cadence * resistance * constant factor
        return (cadence * resistance) / 10
    }
}

extension HomeViewModel: BluetoothManagerDelegate {
    func didUpdateCadenceResponseMetrics(_ metrics: CadenceResponseMetrics) {
        DispatchQueue.main.async {
            self.cadence = metrics.cadence
            self.distance += metrics.incrementalDistance // Increment distance
            self.elapsedTime = metrics.elapsedTime
            self.speed = metrics.speed
            self.power = self.calculatePower(cadence: metrics.cadence, resistance: self.resistance)
            
            let savedMetrics = SavedMetrics(
                cadence: metrics.cadence,
                speed: metrics.speed,
                power: self.power,
                resistance: nil
            )
            self.historicalMetrics.append(savedMetrics)
        }
    }
    
    func didUpdateResistance(_ resistance: Int) {
        DispatchQueue.main.async {
            self.resistance = resistance
            self.power = self.calculatePower(cadence: self.cadence, resistance: resistance)
            
            let savedMetrics = SavedMetrics(
                cadence: nil,
                speed: nil,
                power: self.power,
                resistance: resistance
            )
            self.historicalMetrics.append(savedMetrics)
        }
    }
    
    func didConnectToPeripheral() {
        isConnected = true
    }
    
    func didDiscoverPeripheral(_ peripheral: Peripheral) {
        
    }
}


// Struct to represent saved metrics
struct SavedMetrics: Identifiable {
    let id = UUID()
    let timestamp: Date = .now
    let cadence: Int?
    let speed: Int?
    let power: Int?
    let resistance: Int?
}
