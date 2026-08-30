//
//  PeripheralDetailViewModel.swift
//  TestDrive
//

import CoreBluetooth
import Observation

/// Drives ``PeripheralDetailView``: manages the connection to one peripheral and
/// projects its GATT tree into the sections the screen renders.
@Observable
final class PeripheralDetailViewModel {

    /// The shared Bluetooth explorer.
    let explorer: BluetoothExplorer

    /// The peripheral this screen is inspecting.
    let peripheral: DiscoveredPeripheral

    /// Whether a connection attempt has already been made for this screen.
    private var hasAttemptedConnection = false

    /// The peripheral's display name.
    var title: String { peripheral.displayName }

    /// The current connection state.
    var connectionState: BluetoothConnectionState { explorer.connectionState }

    /// Whether the peripheral is connected and fully discovered.
    var isReady: Bool { explorer.connectionState == .ready }

    /// The discovered services, sorted so the interesting ones come first.
    ///
    /// The Fitness Machine Service leads, then other named services, then anything
    /// vendor-specific — which is usually where an undocumented machine hides the
    /// data it does not expose through the standard characteristics.
    var services: [GATTServiceNode] {
        explorer.services.sorted { first, second in
            let firstRank = rank(for: first.uuid)
            let secondRank = rank(for: second.uuid)
            if firstRank != secondRank { return firstRank < secondRank }
            return first.uuid.uuidString < second.uuid.uuidString
        }
    }

    /// The URL of the live session log, once a connection has been started.
    var logFileURL: URL? { explorer.logFileURL }

    /// The most recent lines written to the log, newest last.
    var recentLogLines: [String] { explorer.recentLogLines }

    /// The fitness-machine telemetry characteristic that most recently produced a
    /// value, together with that value.
    ///
    /// A machine reports through exactly one of the six FTMS data characteristics, but
    /// which one is not knowable in advance, so the app subscribes to all of them and
    /// this picks whichever is actually alive.
    var liveTelemetry: (node: GATTCharacteristicNode, reading: CharacteristicReading)? {
        let candidates = explorer.services
            .flatMap(\.characteristics)
            .filter { GATTIdentifier.fitnessMachineDataCharacteristics.contains($0.uuid) }
            .compactMap { node -> (node: GATTCharacteristicNode, reading: CharacteristicReading)? in
                guard let reading = node.latestReading else { return nil }
                return (node, reading)
            }

        return candidates.max { $0.reading.date < $1.reading.date }
    }

    /// The machine's identity, read from the Device Information service.
    var identityFields: [DecodedField] {
        let uuids = [
            GATTIdentifier.Characteristic.manufacturerName,
            GATTIdentifier.Characteristic.modelNumber,
            GATTIdentifier.Characteristic.serialNumber,
            GATTIdentifier.Characteristic.hardwareRevision,
            GATTIdentifier.Characteristic.firmwareRevision,
            GATTIdentifier.Characteristic.softwareRevision,
            GATTIdentifier.Characteristic.pnpID,
            GATTIdentifier.Characteristic.batteryLevel
        ]

        return uuids.flatMap { uuid -> [DecodedField] in
            explorer.characteristicNode(withUUID: uuid)?.latestReading?.fields ?? []
        }
    }

    /// The machine's declared capabilities, read from Fitness Machine Feature.
    var capabilityFields: [DecodedField] {
        explorer
            .characteristicNode(withUUID: GATTIdentifier.Characteristic.fitnessMachineFeature)?
            .latestReading?
            .fields ?? []
    }

    /// Whether the machine exposes a Fitness Machine Control Point.
    var supportsControlPoint: Bool {
        explorer.characteristicNode(withUUID: GATTIdentifier.Characteristic.fitnessMachineControlPoint) != nil
    }

    /// A count of everything discovered, for the status row.
    var discoverySummary: String {
        let serviceCount = explorer.services.count
        let characteristicCount = explorer.services.reduce(0) { $0 + $1.characteristics.count }
        let valueCount = explorer.services
            .flatMap(\.characteristics)
            .reduce(0) { $0 + $1.totalReadingCount }
        return "\(serviceCount) services · \(characteristicCount) characteristics · \(valueCount) values"
    }

    // MARK: - Initializer

    /// Creates a view model for one peripheral.
    /// - Parameters:
    ///   - explorer: The shared Bluetooth explorer.
    ///   - peripheral: The peripheral to inspect.
    init(explorer: BluetoothExplorer, peripheral: DiscoveredPeripheral) {
        self.explorer = explorer
        self.peripheral = peripheral
    }

    // MARK: - Public Helpers

    /// Connects to the peripheral the first time the screen appears.
    ///
    /// Repeated appearances — after drilling into a characteristic and back, say —
    /// must not tear down a capture that is already running.
    func connectIfNeeded() {
        guard !hasAttemptedConnection else { return }
        hasAttemptedConnection = true
        explorer.connect(to: peripheral)
    }

    /// Reconnects after a failure or a manual disconnect.
    func reconnect() {
        explorer.connect(to: peripheral)
    }

    /// Disconnects and finalises the log file.
    func disconnect() {
        explorer.disconnect()
    }

    /// Reads every readable characteristic again.
    func refreshAll() {
        explorer.refreshAllReadableCharacteristics()
    }

    /// Sends the Fitness Machine Control Point *Request Control* op code.
    func requestControl() {
        explorer.requestFitnessMachineControl()
    }

    // MARK: - Private Helpers

    /// Sorting rank for a service UUID: fitness machine first, then named, then unknown.
    private func rank(for uuid: CBUUID) -> Int {
        if uuid == GATTIdentifier.Service.fitnessMachine { return 0 }
        if GATTIdentifier.isKnown(uuid) { return 1 }
        return 2
    }
}
