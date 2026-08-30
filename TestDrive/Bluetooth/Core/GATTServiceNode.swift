//
//  GATTServiceNode.swift
//  TestDrive
//

import CoreBluetooth

/// A discovered GATT service and its characteristics.
@Observable
final class GATTServiceNode: Identifiable {

    /// The service UUID.
    let uuid: CBUUID

    /// A stable identity derived from the underlying Core Bluetooth object.
    let id: ObjectIdentifier

    /// Whether the peripheral reported this as a primary service.
    let isPrimary: Bool

    /// Discovered characteristics, in discovery order.
    var characteristics: [GATTCharacteristicNode] = []

    /// The UUIDs of any included (secondary) services.
    var includedServiceUUIDs: [CBUUID] = []

    /// The human-readable service name.
    var name: String { GATTIdentifier.name(for: uuid) }

    // MARK: - Initializer

    /// Creates a node for a discovered service.
    /// - Parameter service: The Core Bluetooth service.
    init(service: CBService) {
        self.uuid = service.uuid
        self.id = ObjectIdentifier(service)
        self.isPrimary = service.isPrimary
    }

    // MARK: - Public Helpers

    /// Finds the node for a Core Bluetooth characteristic.
    /// - Parameter characteristic: The characteristic to look up.
    /// - Returns: The matching node, or `nil` when it has not been discovered yet.
    func node(for characteristic: CBCharacteristic) -> GATTCharacteristicNode? {
        characteristics.first { $0.id == ObjectIdentifier(characteristic) }
    }
}
