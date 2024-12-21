//
//  BluetoothManager.swift
//  Testing
//
//  Created by Ricky on 12/20/24.
//

import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate: AnyObject {
    func didUpdateCadenceResponseMetrics(_ metrics: CadenceResponseMetrics)
    func didUpdateResistance(_ resistance: Int)
    func didConnectToPeripheral()
    func didDiscoverPeripheral(_ peripheral: Peripheral)
}

final class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    weak var delegate: BluetoothManagerDelegate?

    private var lastRefreshTime: Date = .now

    private var centralManager: CBCentralManager!
    private var bikePeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var sensorCharacteristic: CBCharacteristic?

    // UUIDs
    private let connectUUID = CBUUID(string: "0bf669f1-45f2-11e7-9598-0800200c9a66")
    private let writeUUID = CBUUID(string: "0bf669f2-45f2-11e7-9598-0800200c9a66")
    private let sensorUUID = CBUUID(string: "0bf669f4-45f2-11e7-9598-0800200c9a66")


    // MARK: - Initializer
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Public
    
    func startScanning() {
        print("Starting scan...")
        centralManager.scanForPeripherals(withServices: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    // MARK: - Bluetooth
    
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

        delegate?.didDiscoverPeripheral(newPeripheral)
        // Avoid duplicates in the list
//        if !discoveredPeripherals.contains(where: { $0.name == newPeripheral.name }) {
//            DispatchQueue.main.async {
//                self.discoveredPeripherals.append(newPeripheral)
//            }
//        }

        guard name.contains("ECH") else { return }
        print("Found Echelon Bike: \(peripheral.name ?? "Unknown")")
        centralManager.stopScan()
        bikePeripheral = peripheral
        bikePeripheral?.delegate = self
        centralManager.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Echelon Bike")")
        delegate?.didConnectToPeripheral()
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

    // MARK: - Private
    
    private func sendActivationMessage(using writeCharacteristic: CBCharacteristic) {
        let activationData: [UInt8] = [0xF0, 0xB0, 0x01, 0x01, 0xA2]
        let data = Data(activationData)
        bikePeripheral?.writeValue(data, for: writeCharacteristic, type: .withResponse)
        print("Sent activation message: \(activationData.map { String(format: "%02x", $0) }.joined())")
        
        // Wait briefly and then request resistance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // 500ms delay
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
        print("Sent resistance request command.")
    }
    
    /// May not actually be distance
    ///
    /// https://github.com/cagnulein/qdomyos-zwift/issues/62
    private func getDistanceFromPacket(_ bytes: [UInt8]) -> Double {
        let convertedData = (UInt16(bytes[7]) << 8) | UInt16(bytes[8])
        let distance = Double(convertedData) / 100.0
        return distance
    }

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
            let elapsedTime = getElapsedTimeFromPacket(bytes)

            // https://github.com/cagnulein/qdomyos-zwift/issues/62
            let speedKPH = 0.37497622 * Double(cadenceValue)
            
            // Calculate distance incrementally based on speed and elapsed time
            let currentTime = Date()
            let elapsedTimeMillis = currentTime.timeIntervalSince(lastRefreshTime) * 1000.0
            let incrementalDistance = (speedKPH / 3600000.0) * elapsedTimeMillis

            let metrics = CadenceResponseMetrics(
                cadence: cadenceValue,
                incrementalDistance: incrementalDistance,
                speed: Int(speedKPH),
                elapsedTime: elapsedTime
            )
            delegate?.didUpdateCadenceResponseMetrics(metrics)
            lastRefreshTime = currentTime
        case 0xD2: // Resistance response
            let resistanceValue = Int(bytes[3])
            delegate?.didUpdateResistance(resistanceValue)
        default:
            print("Unknown notification type: \(String(format: "0x%02X", bytes[1]))")
        }
    }

    private func getElapsedTimeFromPacket(_ bytes: [UInt8]) -> String {
        let totalSeconds = Int((UInt16(bytes[3]) << 8) | UInt16(bytes[4]))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
