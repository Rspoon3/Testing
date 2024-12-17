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
class HomeViewModel: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private(set) var isConnected = false
    private(set) var cadence: Int = 0
    private(set) var resistance: Int = 0
    private(set) var distance: Double = 0
    private(set) var power: Int = 0
    private(set) var speed: Double = 0
    private(set) var elapsedTime: String = "00:00"
    private(set) var discoveredPeripherals: [Peripheral] = []
    
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
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Scanning
    
    func startScanning() {
        print("Starting scan...")
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            print("Bluetooth not powered on.")
            return
        }
        
        startScanning()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi: NSNumber
    ) {
        let name = peripheral.name ?? "Unknown"
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as? Bool ?? false
        
        let newPeripheral = Peripheral(
            name: name,
            rssi: rssi.intValue,
            isConnectable: isConnectable,
            advertisementData: advertisementData
        )
        
        // Avoid duplicates in the list
        if !discoveredPeripherals.contains(where: { $0.name == newPeripheral.name }) {
            DispatchQueue.main.async {
                self.discoveredPeripherals.append(newPeripheral)
            }
        }
        
        guard name.contains("ECH") else { return }
        print("Found Echelon Bike: \(peripheral.name ?? "Unknown")")
        centralManager.stopScan()
        bikePeripheral = peripheral
        bikePeripheral?.delegate = self
        centralManager.connect(peripheral)
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
                sendActivationMessage(using: characteristic)
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
    
    private func sendActivationMessage(using writeCharacteristic: CBCharacteristic) {
        let activationData: [UInt8] = [0xF0, 0xB0, 0x01, 0x01, 0xA2] // Activation message
        let data = Data(activationData)
        
        bikePeripheral?.writeValue(data, for: writeCharacteristic, type: .withResponse)
        print("Sent activation message: \(activationData.map { String(format: "%02x", $0) }.joined())")
        
        // Wait briefly and then request resistance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 500ms delay
            self.requestResistanceUpdate()
        }
    }
    
    private func requestResistanceUpdate() {
        guard let writeCharacteristic else {
            print("Write characteristic not found.")
            return
        }
        
        let resistanceRequest: [UInt8] = [0xA5] // Command to request resistance
        let data = Data(resistanceRequest)
        bikePeripheral?.writeValue(data, for: writeCharacteristic, type: .withResponse)
        print("Sent resistance request command: \(resistanceRequest.map { String(format: "%02x", $0) }.joined())")
    }
    
    private func getDistanceFromPacket(_ bytes: [UInt8]) -> Double {
        let convertedData = (UInt16(bytes[7]) << 8) | UInt16(bytes[8])
        let distance = Double(convertedData) / 100.0
        return distance
    }
    
    private func getElapsedTimeFromPacket(_ bytes: [UInt8]) -> String {
        let totalSeconds = Int((UInt16(bytes[3]) << 8) | UInt16(bytes[4]))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
            let speed = 0.37497622 * Double(cadenceValue)
            
            DispatchQueue.main.async {
                self.cadence = cadenceValue
                self.distance = distanceValue
                self.elapsedTime = elapsedTime
                self.speed = speed
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
        
        //power = pow(1.090112, resistance) * pow(1.015343, cadence) * 7.228958;
    }
}
