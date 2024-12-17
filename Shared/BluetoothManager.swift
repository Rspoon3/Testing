//
//  BluetoothManager.swift
//  Testing
//
//  Created by Ricky on 12/16/24.
//

import SwiftUI
import CoreBluetooth


// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var bikePeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    
    @Published var isConnected = false
    @Published var cadence: Double = 0.0
    @Published var resistance: Int = 0
    @Published var power: Double = 0.0

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Scanning and Connecting
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil)
        print("Scanning for peripherals...")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            print("Bluetooth is not available.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name?.contains("ECHEX") == true { // Match Echelon bike
            print("Echelon bike found! Stopping scan and connecting...")
            bikePeripheral = peripheral
            centralManager.stopScan()
            bikePeripheral?.delegate = self
            centralManager.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to bike!")
        isConnected = true
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == CBUUID(string: "0BF669F1-45F2-11E7-9598-0800200C9A66") {
                print("Found bike service. Discovering characteristics...")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == CBUUID(string: "0BF669F2-45F2-11E7-9598-0800200C9A66") {
                print("Found Write Characteristic. Sending command...")
                writeCharacteristic = characteristic
                sendStartCommand(to: peripheral)
            }
            if characteristic.uuid == CBUUID(string: "0BF669F4-45F2-11E7-9598-0800200C9A66") {
                print("Found Notify Characteristic. Enabling notifications...")
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    // MARK: - Write Start Command
    private func sendStartCommand(to peripheral: CBPeripheral) {
        guard let writeChar = writeCharacteristic else { return }
        let startCommand: [UInt8] = [0xB0, 0x01] // Start sending updates
        let dataToSend = Data(startCommand)
        peripheral.writeValue(dataToSend, for: writeChar, type: .withResponse)
        print("Sent start command to bike.")
    }

    // MARK: - Handling Notifications
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }

        if characteristic.uuid == CBUUID(string: "0BF669F4-45F2-11E7-9598-0800200C9A66") {
            print("Received data: \(value.map { String(format: "%02x", $0) }.joined())")
            parseBikeData(value)
        }
    }

    // MARK: - Parse Data
    private func parseBikeData(_ data: Data) {
        let bytes = [UInt8](data)

        guard bytes.count >= 11 else {
            print("Invalid data length: \(bytes.count)")
            return
        }

        switch bytes[1] {
        case 0xD1: // Cadence notification
            let cadenceRaw = UInt16(bytes[9]) | (UInt16(bytes[10]) << 8)
            let power = computePower(cadence: Int(cadenceRaw), resistance: resistance)
            DispatchQueue.main.async {
                self.cadence = Double(cadenceRaw)
                self.power = power
            }
            print("Cadence: \(cadenceRaw) RPM, Power: \(power) W")

        case 0xD2: // Resistance notification
            let resistanceRaw = Int(bytes[3])
            DispatchQueue.main.async {
                self.resistance = resistanceRaw
            }
            print("Resistance: \(resistanceRaw)")

        default:
            print("Unknown notification type: \(bytes[1])")
        }
    }

    // MARK: - Power Computation
    private func computePower(cadence: Int, resistance: Int) -> Double {
        // Simplified power formula for demonstration
        return Double(cadence * resistance) * 0.1
    }
}
