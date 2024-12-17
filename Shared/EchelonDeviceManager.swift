//
//  EchelonDeviceManager.swift
//  Testing
//
//  Created by Ricky on 12/16/24.
//

import Foundation
import CoreBluetooth
import SwiftUI


import SwiftUI
import CoreBluetooth

// MARK: - SwiftUI View
struct EchelonBikeView: View {
    @StateObject private var viewModel = EchelonBikeViewModel()

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isConnected {
                VStack {
                    Text("Echelon Bike Metrics")
                        .font(.title2)
                    HStack {
                        MetricView(label: "Cadence", value: "\(viewModel.cadence) RPM")
                        MetricView(label: "Resistance", value: "\(viewModel.resistance)")
                        MetricView(label: "Power", value: "\(viewModel.power) W")
                    }
                    HStack {
                        MetricView(label: "Distance", value: "\(viewModel.distance) M")
                        MetricView(label: "ET", value: "\(viewModel.elapsedTime) M")
                    }
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

// MARK: - Metric View
struct MetricView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(label).font(.headline)
            Text(value).font(.largeTitle).foregroundColor(.blue)
        }
        .frame(width: 120, height: 100)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - ViewModel
class EchelonBikeViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isConnected = false
    @Published var cadence: Int = 0
    @Published var resistance: Int = 0
    @Published var distance: Double = 0
    @Published var power: Int = 0
    @Published var elapsedTime: String = "00:00"
    
    private var centralManager: CBCentralManager!
    private var bikePeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var sensorCharacteristic: CBCharacteristic?
    
    // UUIDs
    private let connectUUID = CBUUID(string: "0bf669f1-45f2-11e7-9598-0800200c9a66")
    private let writeUUID = CBUUID(string: "0bf669f2-45f2-11e7-9598-0800200c9a66")
    private let sensorUUID = CBUUID(string: "0bf669f4-45f2-11e7-9598-0800200c9a66")
    
    // Activation message
    private let activationMessage: [UInt8] = [0xF0, 0xB0, 0x01, 0x01, 0xA2]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        print("Starting scan...")
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            print("Bluetooth not powered on.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        if peripheral.name?.contains("ECHEX") == true {
            print("Found Echelon Bike: \(peripheral.name ?? "Unknown")")
            centralManager.stopScan()
            bikePeripheral = peripheral
            bikePeripheral?.delegate = self
            centralManager.connect(peripheral)
        }
    }
    
    private func getElapsedTimeFromPacket(_ bytes: [UInt8]) -> String {
        let totalSeconds = Int((UInt16(bytes[3]) << 8) | UInt16(bytes[4]))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Echelon Bike")")
        isConnected = true
        peripheral.discoverServices([connectUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([writeUUID, sensorUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == writeUUID {
                writeCharacteristic = characteristic
                sendActivationMessage()
            }
            if characteristic.uuid == sensorUUID {
                sensorCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("Enabled notifications for sensor characteristic.")
                
                requestResistanceUpdate()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        parseSensorData(data)
    }
    
    // MARK: - Send Activation Message
    private func sendActivationMessage() {
        guard let writeChar = writeCharacteristic else { return }
        let activationData: [UInt8] = [0xF0, 0xB0, 0x01, 0x01, 0xA2] // Activation message
        let data = Data(activationData)
        
        bikePeripheral?.writeValue(data, for: writeChar, type: .withResponse)
        print("Sent activation message: \(activationData.map { String(format: "%02x", $0) }.joined())")
        
        // Wait briefly and then request resistance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 500ms delay
            self.requestResistanceUpdate()
        }
    }
    
    private func requestResistanceUpdate() {
        guard let writeChar = writeCharacteristic else {
            print("Write characteristic not found.")
            return
        }

        let resistanceRequest: [UInt8] = [0xA5] // Command to request resistance
        let data = Data(resistanceRequest)
        bikePeripheral?.writeValue(data, for: writeChar, type: .withResponse)
        print("Sent resistance request command: \(resistanceRequest.map { String(format: "%02x", $0) }.joined())")
    }
    
    private func getDistanceFromPacket(_ bytes: [UInt8]) -> Double {
        let convertedData = (UInt16(bytes[7]) << 8) | UInt16(bytes[8])
        let distance = Double(convertedData) / 100.0
        return distance
    }
    
    // MARK: - Parse Sensor Data
    private func parseSensorData(_ data: Data) {
        let bytes = [UInt8](data)
        print("Raw Data: \(bytes.map { String(format: "%02x", $0) }.joined())")
        
        guard bytes.count >= 4 else {
            print("Invalid data length.")
            return
        }
        
        switch bytes[1] {
        case 0xD1: // Cadence notification
            let cadenceValue = Int((UInt16(bytes[9]) << 8) + UInt16(bytes[10]))
                   let distanceValue = getDistanceFromPacket(bytes)
                   let elapsedTime = getElapsedTimeFromPacket(bytes)

                   DispatchQueue.main.async {
                       self.cadence = cadenceValue
                       self.distance = distanceValue
                       self.elapsedTime = elapsedTime
                       self.power = self.calculatePower(cadence: cadenceValue, resistance: self.resistance)
                   }
                   print("Cadence: \(cadenceValue) RPM, Distance: \(distanceValue) km, Elapsed Time: \(elapsedTime)")

            
        case 0xD2: // Resistance response
            let resistanceValue = Int(bytes[3]) // Resistance is in byte 3
            DispatchQueue.main.async {
                self.resistance = resistanceValue
                self.power = self.calculatePower(cadence: self.cadence, resistance: resistanceValue)
            }
            print("Resistance Response: \(resistanceValue)")
            
        default:
            print("Unknown notification type: \(String(format: "0x%02X", bytes[1]))")
        }
    }
    private func calculatePower(cadence: Int, resistance: Int) -> Int {
        // Simple power estimation: cadence * resistance * constant factor
        return (cadence * resistance) / 10
    }
}
