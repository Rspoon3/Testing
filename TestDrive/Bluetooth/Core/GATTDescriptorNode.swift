//
//  GATTDescriptorNode.swift
//  TestDrive
//

import CoreBluetooth

/// A discovered GATT descriptor and its most recent value.
@Observable
final class GATTDescriptorNode: Identifiable {

    /// The descriptor UUID.
    let uuid: CBUUID

    /// A stable identity derived from the underlying Core Bluetooth object.
    let id: ObjectIdentifier

    /// The descriptor value as Core Bluetooth reported it, already stringified because
    /// descriptor values arrive as loosely typed `Any`.
    var value: String?

    /// The human-readable descriptor name.
    var name: String { GATTIdentifier.name(for: uuid) }

    // MARK: - Initializer

    /// Creates a node for a discovered descriptor.
    /// - Parameter descriptor: The Core Bluetooth descriptor.
    init(descriptor: CBDescriptor) {
        self.uuid = descriptor.uuid
        self.id = ObjectIdentifier(descriptor)
    }
}
