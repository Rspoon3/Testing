//
//  BluetoothExplorer.swift
//  TestDrive
//

import CoreBluetooth
import Observation
import os

/// Scans for Bluetooth Low Energy peripherals and, once connected, walks the entire
/// GATT database of one of them.
///
/// The discovery sweep is deliberately exhaustive: every service, every
/// characteristic, every descriptor. Readable characteristics are read once,
/// subscribable ones are subscribed to, and every value received is decoded and
/// appended to a ``SessionLogWriter`` on disk in real time. That combination is what
/// turns an undocumented machine into something you can actually inspect.
///
/// Core Bluetooth is created with a `nil` queue, so all delegate callbacks arrive on
/// the main queue and the delegate methods can safely assume main-actor isolation.
@Observable
final class BluetoothExplorer: NSObject {

    /// The availability of the Bluetooth stack.
    var managerState: CBManagerState = .unknown

    /// Peripherals seen during the current or most recent scan.
    var discoveredPeripherals: [DiscoveredPeripheral] = []

    /// Whether a scan is currently running.
    var isScanning = false

    /// When `true`, the scan only reports peripherals advertising the Fitness Machine
    /// Service. When `false`, every advertising peripheral is reported, which is how
    /// you find a machine that hides its service UUIDs from the advertisement.
    var scansFitnessMachinesOnly = false {
        didSet {
            guard isScanning, oldValue != scansFitnessMachinesOnly else { return }
            restartScan()
        }
    }

    /// The peripheral currently connected or being connected to.
    var connectedPeripheral: DiscoveredPeripheral?

    /// The connection lifecycle state of ``connectedPeripheral``.
    var connectionState: BluetoothConnectionState = .disconnected

    /// The GATT tree discovered on ``connectedPeripheral``.
    var services: [GATTServiceNode] = []

    /// The URL of the log file for the current session, once one has been started.
    var logFileURL: URL?

    /// A short running tail of the log, mirrored for on-screen display.
    var recentLogLines: [String] = []

    @ObservationIgnored
    private let logger = Logger(subsystem: "com.testdrive.bluetooth", category: "Explorer")
    @ObservationIgnored
    private var centralManager: CBCentralManager!
    @ObservationIgnored
    private var logWriter: SessionLogWriter?
    @ObservationIgnored
    private var pendingServiceDiscoveryCount = 0

    /// Set when a scan is requested before the Bluetooth stack is ready.
    ///
    /// `CBCentralManager` reports `.unknown` for a short window after creation, and
    /// on a first launch it stays there until the user answers the permission
    /// prompt. A scan requested during that window has to be replayed once
    /// `centralManagerDidUpdateState(_:)` reports `.poweredOn`, or the scan silently
    /// never happens.
    @ObservationIgnored
    private var hasDeferredScanRequest = false

    /// The maximum number of log lines mirrored on screen.
    private static let maximumMirroredLogLines = 200

    // MARK: - Initializer

    /// Creates an explorer and starts the Bluetooth stack.
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Public Helpers

    /// Starts scanning for peripherals, clearing any previous results.
    ///
    /// `CBCentralManagerScanOptionAllowDuplicatesKey` is enabled so repeated
    /// advertisements keep RSSI current and let a peripheral that splits its data
    /// across packets be observed fully.
    func startScan() {
        guard centralManager.state == .poweredOn else {
            hasDeferredScanRequest = true
            logger.notice("Deferring scan until Bluetooth is ready (state \(self.centralManager.state.rawValue))")
            return
        }

        hasDeferredScanRequest = false
        discoveredPeripherals.removeAll()
        isScanning = true

        let serviceFilter = scansFitnessMachinesOnly ? [GATTIdentifier.Service.fitnessMachine] : nil
        centralManager.scanForPeripherals(
            withServices: serviceFilter,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    /// Stops the current scan.
    func stopScan() {
        hasDeferredScanRequest = false
        centralManager.stopScan()
        isScanning = false
    }

    /// Connects to a peripheral and begins the full GATT discovery sweep.
    ///
    /// Starts a new session log file named after the peripheral.
    /// - Parameter discovered: The peripheral to connect to.
    func connect(to discovered: DiscoveredPeripheral) {
        stopScan()
        disconnectWithoutClosingLog()

        connectedPeripheral = discovered
        connectionState = .connecting
        services = []

        let writer = SessionLogWriter(deviceName: discovered.displayName)
        logWriter = writer
        logFileURL = writer.fileURL
        recentLogLines = []

        writer.logSection("ADVERTISEMENT")
        writer.log("Identifier: \(discovered.peripheral.identifier.uuidString)", category: .advertisement)
        writer.log("RSSI: \(discovered.signalStrength) dBm over \(discovered.advertisementCount) packet(s)", category: .advertisement)
        for field in discovered.advertisement.fields {
            writer.log("\(field.label): \(field.value.replacingOccurrences(of: "\n", with: "; "))", category: .advertisement)
        }
        writer.logSection("CONNECTING")

        mirror("Connecting to \(discovered.displayName)…")
        discovered.peripheral.delegate = self
        centralManager.connect(discovered.peripheral, options: nil)
    }

    /// Disconnects the current peripheral and finalises the session log.
    func disconnect() {
        logWriter?.log("Disconnect requested by user", category: .connection)
        logWriter?.finish()
        disconnectWithoutClosingLog()
        logWriter = nil
    }

    /// Reads every readable characteristic again.
    ///
    /// Useful for capturing a second sample of values that change without notifying,
    /// such as a firmware-reported resistance setting.
    func refreshAllReadableCharacteristics() {
        guard let peripheral = connectedPeripheral?.peripheral, connectionState == .ready else { return }
        logWriter?.logSection("MANUAL RE-READ OF ALL READABLE CHARACTERISTICS")
        for service in services {
            for node in service.characteristics where node.properties.isReadable {
                peripheral.readValue(for: node.characteristic)
            }
        }
        mirror("Re-reading all readable characteristics")
    }

    /// Turns a subscription on or off for one characteristic.
    /// - Parameters:
    ///   - node: The characteristic to change.
    ///   - isEnabled: `true` to subscribe, `false` to unsubscribe.
    func setNotifications(_ isEnabled: Bool, for node: GATTCharacteristicNode) {
        guard let peripheral = connectedPeripheral?.peripheral, node.properties.isSubscribable else { return }
        peripheral.setNotifyValue(isEnabled, for: node.characteristic)
        logWriter?.log("\(isEnabled ? "Subscribing to" : "Unsubscribing from") \(node.name) [\(node.uuid.uuidString)]", category: .notify)
    }

    /// Reads one characteristic on demand.
    /// - Parameter node: The characteristic to read.
    func read(_ node: GATTCharacteristicNode) {
        guard let peripheral = connectedPeripheral?.peripheral, node.properties.isReadable else { return }
        peripheral.readValue(for: node.characteristic)
    }

    /// Writes the Fitness Machine Control Point *Request Control* op code (`0x00`).
    ///
    /// A machine will not report certain values, and will reject every other control
    /// op code, until a client has requested control. Nothing about the machine's
    /// current workout is changed by this request — it only opens the control
    /// channel — but it is a write to the equipment, so it is only ever sent when
    /// explicitly invoked.
    func requestFitnessMachineControl() {
        guard let peripheral = connectedPeripheral?.peripheral,
              let controlPoint = characteristicNode(withUUID: GATTIdentifier.Characteristic.fitnessMachineControlPoint) else {
            mirror("No Fitness Machine Control Point on this device")
            return
        }

        let payload = Data([0x00])
        let writeType: CBCharacteristicWriteType = controlPoint.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(payload, for: controlPoint.characteristic, type: writeType)

        logWriter?.log("Wrote Request Control (0x00) to Fitness Machine Control Point", category: .write)
        mirror("Requested control of the fitness machine")
    }

    /// Finds a discovered characteristic by UUID.
    /// - Parameter uuid: The characteristic UUID.
    /// - Returns: The first matching node, or `nil`.
    func characteristicNode(withUUID uuid: CBUUID) -> GATTCharacteristicNode? {
        for service in services {
            if let match = service.characteristics.first(where: { $0.uuid == uuid }) {
                return match
            }
        }
        return nil
    }

    /// The current contents of the session log file.
    /// - Returns: The log text, or `nil` when no session has been started.
    func currentLogContents() -> String? {
        logWriter?.currentContents()
    }

    // MARK: - Private Helpers

    /// Tears down the connection without finalising the log file.
    private func disconnectWithoutClosingLog() {
        if let peripheral = connectedPeripheral?.peripheral {
            peripheral.delegate = nil
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectionState = .disconnected
        pendingServiceDiscoveryCount = 0
    }

    /// Stops and immediately restarts the scan, applying a changed service filter.
    private func restartScan() {
        stopScan()
        startScan()
    }

    /// Adds a line to the on-screen log mirror and to the file.
    private func mirror(_ message: String, category: SessionLogWriter.LogCategory = .info) {
        logWriter?.log(message, category: category)
        recentLogLines.append(message)
        if recentLogLines.count > Self.maximumMirroredLogLines {
            recentLogLines.removeFirst(recentLogLines.count - Self.maximumMirroredLogLines)
        }
    }

    /// Finds the node for a Core Bluetooth characteristic across every discovered service.
    private func node(for characteristic: CBCharacteristic) -> GATTCharacteristicNode? {
        for service in services {
            if let match = service.node(for: characteristic) {
                return match
            }
        }
        return nil
    }

    /// Records a received value on the matching node and writes it to the log.
    private func record(
        _ data: Data,
        for characteristic: CBCharacteristic,
        isNotification: Bool
    ) {
        let fields = GATTDecoderRegistry.decode(data, for: characteristic.uuid)
        let reading = CharacteristicReading(data: data, fields: fields, isNotification: isNotification)

        node(for: characteristic)?.append(reading)

        logWriter?.logValue(
            source: "\(GATTIdentifier.name(for: characteristic.uuid)) [\(characteristic.uuid.uuidString)]",
            data: data,
            fields: fields,
            category: isNotification ? .notify : .read
        )
    }

    /// Renders a descriptor value, which Core Bluetooth delivers as a loosely typed
    /// `Any` whose concrete type depends on the descriptor.
    private static func description(forDescriptorValue value: Any?) -> String {
        switch value {
        case let data as Data:
            "\(data.hexDescription) (\(data.count) bytes)"
        case let string as String:
            string
        case let number as NSNumber:
            number.stringValue
        case .some(let other):
            String(describing: other)
        case .none:
            "nil"
        }
    }

    /// Marks discovery complete once every service has reported its characteristics.
    private func finishDiscoveryIfComplete() {
        guard pendingServiceDiscoveryCount == 0, connectionState == .discovering else { return }

        connectionState = .ready

        let characteristicCount = services.reduce(0) { $0 + $1.characteristics.count }
        logWriter?.logSection("DISCOVERY COMPLETE — \(services.count) service(s), \(characteristicCount) characteristic(s)")
        mirror("Discovery complete: \(services.count) services, \(characteristicCount) characteristics")
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothExplorer: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MainActor.assumeIsolated {
            managerState = central.state
            logger.notice("Bluetooth state: \(central.state.rawValue)")

            guard central.state == .poweredOn else {
                isScanning = false
                connectionState = .disconnected
                return
            }

            if hasDeferredScanRequest || (!isScanning && connectedPeripheral == nil) {
                startScan()
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        MainActor.assumeIsolated {
            let advertisement = AdvertisementSnapshot(advertisementData: advertisementData)
            let signalStrength = RSSI.intValue

            if let existing = discoveredPeripherals.first(where: { $0.peripheral.identifier == peripheral.identifier }) {
                existing.update(advertisement: advertisement, signalStrength: signalStrength)
                return
            }

            let discovered = DiscoveredPeripheral(
                peripheral: peripheral,
                advertisement: advertisement,
                signalStrength: signalStrength
            )
            discoveredPeripherals.append(discovered)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MainActor.assumeIsolated {
            connectionState = .discovering
            mirror("Connected. Discovering all services…", category: .connection)
            peripheral.discoverServices(nil)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            let reason = error?.localizedDescription ?? "unknown error"
            connectionState = .failed(reason)
            mirror("Failed to connect: \(reason)", category: .error)
            logWriter?.finish()
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            connectionState = .disconnected
            if let error {
                mirror("Disconnected: \(error.localizedDescription)", category: .error)
            } else {
                mirror("Disconnected", category: .connection)
            }
            logWriter?.finish()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothExplorer: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        MainActor.assumeIsolated {
            if let error {
                mirror("Service discovery failed: \(error.localizedDescription)", category: .error)
                connectionState = .failed(error.localizedDescription)
                return
            }

            let discovered = peripheral.services ?? []
            pendingServiceDiscoveryCount = discovered.count
            logWriter?.logSection("SERVICES — \(discovered.count) found")

            for service in discovered {
                let node = GATTServiceNode(service: service)
                services.append(node)
                logWriter?.log(
                    "\(node.name) [\(service.uuid.uuidString)] \(service.isPrimary ? "primary" : "secondary")",
                    category: .discovery
                )
                peripheral.discoverCharacteristics(nil, for: service)
                peripheral.discoverIncludedServices(nil, for: service)
            }

            finishDiscoveryIfComplete()
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            pendingServiceDiscoveryCount = max(0, pendingServiceDiscoveryCount - 1)

            guard let serviceNode = services.first(where: { $0.id == ObjectIdentifier(service) }) else { return }

            if let error {
                mirror("Characteristic discovery failed for \(serviceNode.name): \(error.localizedDescription)", category: .error)
                finishDiscoveryIfComplete()
                return
            }

            let characteristics = service.characteristics ?? []
            logWriter?.log(
                "\(serviceNode.name): \(characteristics.count) characteristic(s)",
                category: .discovery
            )

            for characteristic in characteristics {
                let node = GATTCharacteristicNode(characteristic: characteristic)
                serviceNode.characteristics.append(node)

                logWriter?.log(
                    "  \(node.name) [\(characteristic.uuid.uuidString)] — \(characteristic.properties.summary)",
                    category: .discovery
                )

                peripheral.discoverDescriptors(for: characteristic)

                if characteristic.properties.isReadable {
                    peripheral.readValue(for: characteristic)
                }

                if characteristic.properties.isSubscribable {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }

            finishDiscoveryIfComplete()
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            guard error == nil,
                  let serviceNode = services.first(where: { $0.id == ObjectIdentifier(service) }),
                  let included = service.includedServices,
                  !included.isEmpty else {
                return
            }

            serviceNode.includedServiceUUIDs = included.map(\.uuid)
            logWriter?.log(
                "\(serviceNode.name) includes: \(included.map(\.uuid.uuidString).joined(separator: ", "))",
                category: .discovery
            )
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            if let error {
                node(for: characteristic)?.errorDescription = error.localizedDescription
                logWriter?.log(
                    "Read failed for \(GATTIdentifier.name(for: characteristic.uuid)): \(error.localizedDescription)",
                    category: .error
                )
                return
            }

            guard let data = characteristic.value else { return }
            let isNotification = node(for: characteristic)?.isNotifying ?? false
            record(data, for: characteristic, isNotification: isNotification)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            let characteristicNode = node(for: characteristic)
            characteristicNode?.isNotifying = characteristic.isNotifying

            if let error {
                characteristicNode?.errorDescription = error.localizedDescription
                logWriter?.log(
                    "Subscription failed for \(GATTIdentifier.name(for: characteristic.uuid)): \(error.localizedDescription)",
                    category: .error
                )
                return
            }

            logWriter?.log(
                "\(characteristic.isNotifying ? "Subscribed to" : "Unsubscribed from") \(GATTIdentifier.name(for: characteristic.uuid)) [\(characteristic.uuid.uuidString)]",
                category: .notify
            )
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            guard error == nil,
                  let characteristicNode = node(for: characteristic),
                  let descriptors = characteristic.descriptors else {
                return
            }

            for descriptor in descriptors {
                characteristicNode.descriptors.append(GATTDescriptorNode(descriptor: descriptor))
                peripheral.readValue(for: descriptor)
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            guard error == nil else { return }

            let value = Self.description(forDescriptorValue: descriptor.value)
            for service in services {
                for characteristicNode in service.characteristics {
                    if let match = characteristicNode.descriptors.first(where: { $0.id == ObjectIdentifier(descriptor) }) {
                        match.value = value
                        logWriter?.log(
                            "\(characteristicNode.name) → \(match.name): \(value)",
                            category: .descriptor
                        )
                        return
                    }
                }
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            if let error {
                logWriter?.log(
                    "Write failed for \(GATTIdentifier.name(for: characteristic.uuid)): \(error.localizedDescription)",
                    category: .error
                )
            } else {
                logWriter?.log(
                    "Write acknowledged by \(GATTIdentifier.name(for: characteristic.uuid))",
                    category: .write
                )
            }
        }
    }
}
