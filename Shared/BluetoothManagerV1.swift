//
//  BluetoothManagerV1.swift
//  Testing
//
//  Created by Ricky on 12/16/24.
//



import SwiftUI
import CoreBluetooth

// MARK: - Bluetooth Manager
class BluetoothManagerV1: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var bikePeripheral: CBPeripheral?
    @Published var discoveredPeripherals: [Peripheral] = []

    @Published var isConnected = false
    @Published var odometer: Double = 0.0
    @Published var resistance: Int = 0
    @Published var speed: Double = 0.0

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil) // Replace with bike's specific UUIDs
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            print("Bluetooth is not available.")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        // Log discovered peripheral information
//        print("Discovered Peripheral: \(peripheral.name ?? "Unknown")")
//        print("Advertisement Data: \(advertisementData)")
//        print("RSSI (Signal Strength): \(RSSI)")
        
        
        let name = peripheral.name ?? "Unknown"
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as? Bool ?? false
        
        let newPeripheral = Peripheral(
            name: name,
            rssi: RSSI.intValue,
            isConnectable: isConnectable,
            advertisementData: advertisementData
        )
        
        // Avoid duplicates in the list
        if !discoveredPeripherals.contains(where: { $0.name == newPeripheral.name }) {
            DispatchQueue.main.async {
                self.discoveredPeripherals.append(newPeripheral)
            }
        }
        
//        print("Discovered Peripheral: \(newPeripheral)")

        // Check if the peripheral matches your bike
        if let peripheralName = peripheral.name, peripheralName.contains("ECHEX") { // Replace "Echelon" with your bike's specific name if known
            print("Echelon bike found! Stopping scan and connecting...")
            bikePeripheral = peripheral
            centralManager.stopScan()
            centralManager.connect(peripheral)
        } else {
            print("Peripheral does not match the Echelon bike. Continuing scan...")
        }
    }
//
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
//        print(#function)
//        if peripheral.name?.contains("Echelon") == true { // Replace with exact name if known
//            bikePeripheral = peripheral
//            centralManager.stopScan()
//            centralManager.connect(peripheral)
//        }
//    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        bikePeripheral = peripheral
        bikePeripheral?.delegate = self
        bikePeripheral?.discoverServices(nil) // Replace with specific service UUIDs if known
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to bike: \(error?.localizedDescription ?? "Unknown error")")
    }

    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("No services found for peripheral: \(peripheral.name ?? "Unknown")")
            return
        }
        
        print("Discovered \(services.count) services for \(peripheral.name ?? "Unknown"):")
        for service in services {
            print("Service UUID: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("No characteristics found for service \(service.uuid)")
            return
        }

        print("Discovered \(characteristics.count) characteristics for service \(service.uuid):")
        for characteristic in characteristics {
            print("Characteristic UUID: \(characteristic.uuid) | Properties: \(characteristic.properties)")
            
            // Enable notifications for readable/notify characteristics
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                print("Enabled notifications for characteristic \(characteristic.uuid)")
            }
            
            // Read value for readable characteristics
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
                print("Reading value for characteristic \(characteristic.uuid)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }

        guard let value = characteristic.value else {
            print("No data received for characteristic \(characteristic.uuid)")
            return
        }

        // Log the characteristic UUID and raw data for debugging
        print("Received update for characteristic: \(characteristic.uuid)")
        print("Raw Data: \(value.map { String(format: "%02x", $0) }.joined())")

        // Parse the data if it's a known characteristic
        parseBikeData(from: value)
    }
    
    private func parseBikeData(from data: Data) {
        let bytes = [UInt8](data)

        // Ensure data has enough length
        guard bytes.count >= 8 else {
            print("Invalid data length: \(bytes.count)")
            return
        }

        // Parse Speed (Bytes 0–1, UInt16)
        let speedDecimetersPerSecond = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
        let speedKmH = Double(speedDecimetersPerSecond) / 10.0

        // Parse Resistance (Bytes 2–3, UInt16)
        let resistance = UInt16(bytes[2]) | (UInt16(bytes[3]) << 8)

        // Parse Odometer (Bytes 4–7, UInt32)
        let odometerMeters = UInt32(bytes[4]) |
                             (UInt32(bytes[5]) << 8) |
                             (UInt32(bytes[6]) << 16) |
                             (UInt32(bytes[7]) << 24)
        let odometerKm = Double(odometerMeters) / 1000.0

        // Update SwiftUI published properties
        DispatchQueue.main.async {
            self.speed = speedKmH
            self.resistance = Int(resistance)
            self.odometer = odometerKm
        }

        // Debugging logs
        print("Parsed Data -> Speed: \(speedKmH) km/h, Resistance: \(resistance), Odometer: \(odometerKm) km")
    }
}
