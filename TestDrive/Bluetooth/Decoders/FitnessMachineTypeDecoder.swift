//
//  FitnessMachineTypeDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the Service Data that a Fitness Machine Service peripheral puts in its
/// advertising packet.
///
/// This is what lets Apple TV recognise a stair climber before connecting to it:
/// a flags byte followed by a 16-bit Fitness Machine Type bit field that declares
/// what kind of machine is advertising.
enum FitnessMachineTypeDecoder {

    /// The machine-type bits of the Fitness Machine Service advertising data.
    static let machineTypeNames = [
        "Treadmill",
        "Cross Trainer",
        "Step Climber",
        "Stair Climber",
        "Rower",
        "Indoor Bike"
    ]

    // MARK: - Public Helpers

    /// Decodes the Fitness Machine Service advertising Service Data.
    /// - Parameter data: The raw service data for UUID `0x1826`.
    /// - Returns: The flags and the declared machine types.
    static func decode(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)

        guard let flags = reader.uint8() else {
            return [DecodedField(label: "Error", value: "Empty fitness machine service data")]
        }

        var fields: [DecodedField] = [
            DecodedField(
                label: "Service Data Flags",
                value: flags & 0x01 != 0 ? "Fitness Machine Available" : "Fitness Machine Not Available",
                detail: "0x\(String(format: "%02X", flags))"
            )
        ]

        if let machineType = reader.uint16() {
            let types = BitFieldFormatter.setFlags(in: machineType, names: machineTypeNames)
            fields.append(DecodedField(
                label: "Fitness Machine Type",
                value: types.isEmpty ? "None declared" : types.joined(separator: ", "),
                detail: "0x\(String(format: "%04X", machineType))"
            ))
        }

        if reader.remainingByteCount > 0 {
            fields.append(DecodedField(
                label: "Undecoded Trailing Bytes",
                value: "\(reader.remainingByteCount) byte(s)",
                detail: reader.remainingBytes.hexDescription
            ))
        }

        return fields
    }
}
