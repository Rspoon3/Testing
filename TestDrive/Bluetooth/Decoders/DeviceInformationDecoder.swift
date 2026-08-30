//
//  DeviceInformationDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the small fixed-layout characteristics that identify a device:
/// battery level, PnP ID, System ID, appearance, and body sensor location.
enum DeviceInformationDecoder {

    // MARK: - Public Helpers

    /// Decodes a Battery Level payload (`0x2A19`).
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The battery percentage.
    static func decodeBatteryLevel(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)
        guard let level = reader.uint8() else {
            return [DecodedField(label: "Error", value: "Empty battery payload")]
        }
        return [.measurement("Battery Level", level, unit: "%")]
    }

    /// Decodes a PnP ID payload (`0x2A50`).
    ///
    /// This is often the quickest way to identify the Bluetooth module inside an
    /// otherwise undocumented machine.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The vendor ID source, vendor ID, product ID, and product version.
    static func decodePnPID(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)

        guard let source = reader.uint8(),
              let vendorID = reader.uint16(),
              let productID = reader.uint16(),
              let productVersion = reader.uint16() else {
            return [DecodedField(label: "Error", value: "Payload too short for a 7-byte PnP ID")]
        }

        let sourceName = switch source {
        case 0x01: "Bluetooth SIG"
        case 0x02: "USB Implementers Forum"
        default: "Reserved (0x\(String(format: "%02X", source)))"
        }

        return [
            DecodedField(label: "Vendor ID Source", value: sourceName),
            DecodedField(label: "Vendor ID", value: "0x\(String(format: "%04X", vendorID))", detail: "\(vendorID)"),
            DecodedField(label: "Product ID", value: "0x\(String(format: "%04X", productID))", detail: "\(productID)"),
            DecodedField(
                label: "Product Version",
                value: "\(productVersion >> 8).\((productVersion >> 4) & 0x0F).\(productVersion & 0x0F)",
                detail: "0x\(String(format: "%04X", productVersion))"
            )
        ]
    }

    /// Decodes a System ID payload (`0x2A23`).
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The manufacturer identifier and the organizationally unique identifier.
    static func decodeSystemID(_ data: Data) -> [DecodedField] {
        guard data.count >= 8 else {
            return [DecodedField(label: "Error", value: "Payload too short for an 8-byte System ID")]
        }
        let manufacturerIdentifier = data.prefix(5)
        let organizationallyUniqueIdentifier = data.dropFirst(5).prefix(3)
        return [
            DecodedField(label: "Manufacturer Identifier", value: manufacturerIdentifier.hexDescription),
            DecodedField(label: "Organizationally Unique Identifier", value: organizationallyUniqueIdentifier.hexDescription)
        ]
    }

    /// Decodes an Appearance payload (`0x2A01`).
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The appearance category and subcategory.
    static func decodeAppearance(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)
        guard let value = reader.uint16() else {
            return [DecodedField(label: "Error", value: "Payload too short for a 2-byte appearance")]
        }
        return [
            DecodedField(
                label: "Appearance",
                value: "Category \(value >> 6), subcategory \(value & 0x3F)",
                detail: "0x\(String(format: "%04X", value))"
            )
        ]
    }

    /// Decodes a Body Sensor Location payload (`0x2A38`).
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The sensor location name.
    static func decodeBodySensorLocation(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)
        guard let location = reader.uint8() else {
            return [DecodedField(label: "Error", value: "Empty body sensor location payload")]
        }
        let name = switch location {
        case 0: "Other"
        case 1: "Chest"
        case 2: "Wrist"
        case 3: "Finger"
        case 4: "Hand"
        case 5: "Ear Lobe"
        case 6: "Foot"
        default: "Reserved (\(location))"
        }
        return [DecodedField(label: "Body Sensor Location", value: name)]
    }

    /// Decodes a Preferred Connection Parameters payload (`0x2A04`).
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The connection interval bounds, slave latency, and supervision timeout.
    static func decodePreferredConnectionParameters(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)
        guard let minimumInterval = reader.uint16(),
              let maximumInterval = reader.uint16(),
              let latency = reader.uint16(),
              let timeout = reader.uint16() else {
            return [DecodedField(label: "Error", value: "Payload too short for 8 bytes of connection parameters")]
        }
        return [
            DecodedField(label: "Minimum Connection Interval", value: String(format: "%.2f ms", Double(minimumInterval) * 1.25)),
            DecodedField(label: "Maximum Connection Interval", value: String(format: "%.2f ms", Double(maximumInterval) * 1.25)),
            DecodedField(label: "Slave Latency", value: "\(latency) intervals"),
            DecodedField(label: "Supervision Timeout", value: String(format: "%.0f ms", Double(timeout) * 10))
        ]
    }
}
