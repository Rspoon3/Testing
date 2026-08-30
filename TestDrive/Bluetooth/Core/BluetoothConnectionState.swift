//
//  BluetoothConnectionState.swift
//  TestDrive
//

import CoreBluetooth

/// Where a peripheral is in the connect-and-discover lifecycle.
enum BluetoothConnectionState: Equatable {
    case disconnected
    case connecting
    case discovering
    case ready
    case failed(String)

    /// A short label suitable for a status row.
    var label: String {
        switch self {
        case .disconnected: "Disconnected"
        case .connecting: "Connecting…"
        case .discovering: "Discovering services…"
        case .ready: "Connected"
        case .failed(let reason): "Failed — \(reason)"
        }
    }

    /// Whether a connection attempt or connection is currently in flight.
    var isBusy: Bool {
        self == .connecting || self == .discovering
    }
}

extension CBManagerState {
    /// A human-readable description of the Bluetooth stack's availability.
    var label: String {
        switch self {
        case .poweredOn: "Ready"
        case .poweredOff: "Bluetooth is turned off"
        case .unauthorized: "TestDrive is not allowed to use Bluetooth"
        case .unsupported: "This device does not support Bluetooth Low Energy"
        case .resetting: "Bluetooth is resetting"
        case .unknown: "Bluetooth state is unknown"
        @unknown default: "Unrecognised Bluetooth state"
        }
    }
}
