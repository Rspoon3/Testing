//
//  EchelonDeviceManager.swift
//  Testing
//
//  Created by Ricky on 12/16/24.
//

import Foundation
import CoreBluetooth
import SwiftUI

//}

// Updated view for debugging
struct DeviceConnectionView: View {
    @StateObject private var deviceManager = EchelonDeviceManager()
    @State private var parsedDataString = ""
    
    var body: some View {
        VStack {
            List(deviceManager.discoveredDevices, id: \.identifier) { device in
                HStack {
                    Text(device.name ?? "Unknown Device")
                    Spacer()
                    Button("Connect") {
                        deviceManager.connectToDevice(device)
                    }
                }
            }
            
            Text(parsedDataString)
                .font(.monospaced(.body)())
                .padding()
        }
        .onReceive(deviceManager.$sensorData) { data in
            guard let data = data else { return }
            let sensorData = EchelonSensorData(rawData: data)
            parsedDataString = sensorData.description
            deviceManager.parseReceivedData(data)
        }
        .onAppear {
            deviceManager.startScanning()
        }
    }
}


//
//  EchelonDeviceManager.swift
//  Testing
//
//  Created by Ricky on 12/16/24.
//

import Foundation
import CoreBluetooth
import SwiftUI
import Combine

class EchelonDeviceManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // UUIDs for Echelon Services
    private let deviceUUID = CBUUID(string: "0bf669f0-45f2-11e7-9598-0800200c9a66")
    private let connectUUID = CBUUID(string: "0bf669f1-45f2-11e7-9598-0800200c9a66")
    private let writeUUID = CBUUID(string: "0bf669f2-45f2-11e7-9598-0800200c9a66")
    private let sensorUUID = CBUUID(string: "0bf669f4-45f2-11e7-9598-0800200c9a66")
    
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var selectedDevice: CBPeripheral?
    @Published var sensorData: Data?
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var sensorCharacteristic: CBCharacteristic?
    
    // Activation message matching Arduino code
    private let activationMessage: [UInt8] = [0xF0, 0xB0, 0x01, 0x01, 0xA2]
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        
        centralManager.scanForPeripherals(
            withServices: [deviceUUID],
            options: nil
        )
    }
    
    func connectToDevice(_ peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            print("Bluetooth is powered off")
        default:
            print("Central manager is in unexpected state")
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        peripheral.discoverServices([connectUUID])
    }
    
    // MARK: - CBPeripheralDelegate Methods
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(
                [writeUUID, sensorUUID],
                for: service
            )
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == writeUUID {
                writeCharacteristic = characteristic
                // Send activation message
                sendActivationMessage()
            }
            
            if characteristic.uuid == sensorUUID {
                sensorCharacteristic = characteristic
                // Enable notifications
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    // Send activation message
    private func sendActivationMessage() {
        guard let peripheral = connectedPeripheral,
              let writeChar = writeCharacteristic else {
            print("Cannot send activation message")
            return
        }
        
        let data = Data(activationMessage)
        peripheral.writeValue(
            data,
            for: writeChar,
            type: .withResponse
        )
        print("Sent activation message: \(activationMessage.map { String(format: "%02x", $0) }.joined(separator: " "))")
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value else { return }
        
        DispatchQueue.main.async {
            self.sensorData = data
            self.printDetailedDataInfo(data)
        }
    }
    
    // Detailed data debugging
    private func printDetailedDataInfo(_ data: Data) {
        let bytes = [UInt8](data)
        print("Received Data:")
        print("Length: \(bytes.count) bytes")
        print("Raw Bytes: \(bytes.map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        // Detailed byte analysis
        bytes.enumerated().forEach { index, byte in
            print("Byte \(index): 0x\(String(format: "%02x", byte))")
        }
    }
}




struct EchelonSensorData {
    enum NotificationType {
        case cadence(Int)
        case resistance(Int)
        case unknown
    }
    
    var type: NotificationType
    var rawBytes: [UInt8]
    
    init(rawData: Data) {
        rawBytes = [UInt8](rawData)
        
        switch rawBytes[1] {
        case 0xD1: // Cadence notification
            // Extract cadence from bytes 9-10 (little-endian)
            let cadence = Int((UInt16(rawBytes[9]) << 8) + UInt16(rawBytes[10]))
            type = .cadence(cadence)
        
        case 0xD2: // Resistance notification
            // Extract resistance from byte 3
            let resistance = Int(rawBytes[3])
            type = .resistance(resistance)
        
        default:
            type = .unknown
        }
    }
    
    // Detailed description for debugging
    var description: String {
        switch type {
        case .cadence(let value):
            return "Cadence: \(value) rpm"
        case .resistance(let value):
            return "Resistance: \(value)"
        case .unknown:
            return "Unknown notification type"
        }
    }
}

// Extension to EchelonDeviceManager to integrate parsing
extension EchelonDeviceManager {
    func parseReceivedData(_ data: Data) {
        let sensorData = EchelonSensorData(rawData: data)
        
        DispatchQueue.main.async {
            switch sensorData.type {
            case .cadence(let cadence):
                print("Parsed Cadence: \(cadence)")
                // You can update published properties here
                // self.currentCadence = cadence
            case .resistance(let resistance):
                print("Parsed Resistance: \(resistance)")
                // self.currentResistance = resistance
            case .unknown:
                print("Unknown data type")
            }
            
            // Print raw bytes for reference
            print("Raw Bytes: \(sensorData.rawBytes.map { String(format: "%02x", $0) }.joined(separator: " "))")
        }
    }
}




class EchelonBikeViewModel: ObservableObject {
    @Published var cadence: Int = 0
    @Published var resistance: Int = 0
    @Published var discoveredDevices: [CBPeripheral] = []
    private var cancellables = Set<AnyCancellable>()
    
    var deviceManager = EchelonDeviceManager()
    
    init() {
        setupDeviceManagerObserving()
    }
    
    private func setupDeviceManagerObserving() {
        deviceManager.$sensorData
            .compactMap { $0 }
            .map { EchelonSensorData(rawData: $0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sensorData in
                switch sensorData.type {
                case .cadence(let value):
                    self?.cadence = value
                case .resistance(let value):
                    self?.resistance = value
                case .unknown:
                    break
                }
            }
            .store(in: &cancellables)
    }
}

struct EchelonBikeView: View {
    @StateObject private var viewModel = EchelonBikeViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Device Selection
            Section(header: Text("Devices").font(.headline)) {
                List(viewModel.discoveredDevices, id: \.identifier) { device in
                    HStack {
                        Text(device.name ?? "Unknown Device")
                        Spacer()
                        Button("Connect") {
                            // Implement connection logic
                        }
                    }
                }
                .frame(height: 200)
            }
            
            // Bike Data Display
            Section(header: Text("Bike Data").font(.headline)) {
                HStack {
                    VStack {
                        Text("Cadence")
                            .font(.headline)
                        Text("\(viewModel.cadence)")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    
                    VStack {
                        Text("Resistance")
                            .font(.headline)
                        Text("\(viewModel.resistance)")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            // Raw Data Debugging
            Section(header: Text("Debug Info").font(.headline)) {
                ScrollView {
                    Text(debugOutput)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 100)
            }
        }
        .padding()
        .onAppear {
            viewModel.deviceManager.startScanning()
        }
    }
    
    // Debugging output
    private var debugOutput: String {
        """
        Cadence: \(viewModel.cadence)
        Resistance: \(viewModel.resistance)
        """
    }
}

// Existing EchelonDeviceManager remains the same as in previous implementation


//Key features:
//1. Displays both cadence and resistance
//2. Uses a view model to separate data management
//3. Provides a clean UI with sections for device selection, bike data, and debugging
//4. Allows for easy expansion and customization
//
//Recommended next steps:
//1. Verify the data parsing works as expected
//2. Add more detailed error handling
//3. Implement connection logic for discovered devices
//
//Would you like me to elaborate on any part of the implementation?
//Last edited just now
                                            
