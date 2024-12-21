//
//  MockBluetoothManager.swift
//  Testing
//
//  Created by Ricky on 12/20/24.
//

import Foundation

final class MockBluetoothManager: BluetoothManagerProtocol {
    weak var delegate: BluetoothManagerDelegate?
    private var dataGenerator = RealisticMockDataGenerator()
    private var timer: Timer?
    private var currentTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var distance: Double = 0

    func startScanning() {
        print("MockBluetoothManager: Scanning started.")

        // Simulate discovering a peripheral
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.delegate?.didDiscoverPeripheral(Peripheral(
                name: "Mock Echelon Bike",
                rssi: -60,
                isConnectable: true,
                advertisementData: [:]
            ))
        }

        // Simulate connecting to a peripheral
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.delegate?.didConnectToPeripheral()
            self.startEmittingMetrics()
//        }
    }

    func stopScanning() {
        print("MockBluetoothManager: Scanning stopped.")
    }

    private func startEmittingMetrics() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.emitMetrics()
        }
    }
    
    private func emitMetrics() {
        // Generate realistic mock values
        let cadence = dataGenerator.nextCadence()
        let resistance = dataGenerator.nextResistance()
        let speed = dataGenerator.nextSpeed()
        
        // Calculate incremental distance
        let elapsedTime = Date().timeIntervalSince1970
        let elapsedTimeMillis = (elapsedTime - lastUpdateTime) * 1000.0 // Time in milliseconds

        // Update total distance and last update time
        distance += 0.001
        lastUpdateTime = elapsedTime

        // Elapsed time in minutes:seconds format
        currentTime += 1.0
        let elapsedTimeFormatted = formatElapsedTime(currentTime)

        // Emit cadence response metrics
        let metrics = CadenceResponseMetrics(
            cadence: cadence,
            incrementalDistance: distance,
            speed: speed,
            elapsedTime: elapsedTimeFormatted
        )
        delegate?.didUpdateCadenceResponseMetrics(metrics)

        // Emit resistance value
        delegate?.didUpdateResistance(resistance)
    }

    private func formatElapsedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
