//
//  GATTCharacteristicNode.swift
//  TestDrive
//

import CoreBluetooth

/// A discovered GATT characteristic, its descriptors, and the history of values
/// received from it.
@Observable
final class GATTCharacteristicNode: Identifiable {

    /// The maximum number of readings retained per characteristic.
    ///
    /// A stair climber notifying at 1 Hz for an hour would otherwise accumulate
    /// thousands of entries in memory. The full history always survives in the
    /// session log file on disk.
    static let maximumRetainedReadings = 50

    /// The characteristic UUID.
    let uuid: CBUUID

    /// A stable identity derived from the underlying Core Bluetooth object.
    let id: ObjectIdentifier

    /// The GATT properties declared by the peripheral.
    let properties: CBCharacteristicProperties

    /// The underlying Core Bluetooth characteristic, retained so reads, writes, and
    /// subscription changes can be issued later.
    let characteristic: CBCharacteristic

    /// Discovered descriptors.
    var descriptors: [GATTDescriptorNode] = []

    /// Received values, most recent first, capped at ``maximumRetainedReadings``.
    var readings: [CharacteristicReading] = []

    /// Whether the app is currently subscribed to this characteristic.
    var isNotifying = false

    /// The number of values received during this session, including any dropped from
    /// ``readings`` by the cap.
    var totalReadingCount = 0

    /// The most recent error reported for this characteristic, if any.
    var errorDescription: String?

    /// The human-readable characteristic name.
    var name: String { GATTIdentifier.name(for: uuid) }

    /// The most recent value received.
    var latestReading: CharacteristicReading? { readings.first }

    // MARK: - Initializer

    /// Creates a node for a discovered characteristic.
    /// - Parameter characteristic: The Core Bluetooth characteristic.
    init(characteristic: CBCharacteristic) {
        self.uuid = characteristic.uuid
        self.id = ObjectIdentifier(characteristic)
        self.properties = characteristic.properties
        self.characteristic = characteristic
    }

    // MARK: - Public Helpers

    /// Records a newly received value, trimming the history to the retention cap.
    /// - Parameter reading: The reading to store.
    func append(_ reading: CharacteristicReading) {
        totalReadingCount += 1
        readings.insert(reading, at: 0)
        if readings.count > Self.maximumRetainedReadings {
            readings.removeLast(readings.count - Self.maximumRetainedReadings)
        }
    }
}
