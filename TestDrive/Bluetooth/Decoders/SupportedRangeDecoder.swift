//
//  SupportedRangeDecoder.swift
//  TestDrive
//

import CoreBluetooth

/// Decodes the five Fitness Machine Service supported-range characteristics
/// (`0x2AD4`–`0x2AD8`), each of which reports a minimum, a maximum, and a
/// minimum increment for one settable parameter.
enum SupportedRangeDecoder {

    // MARK: - Public Helpers

    /// Decodes a supported-range payload for the given characteristic.
    /// - Parameters:
    ///   - data: The raw characteristic value.
    ///   - uuid: The characteristic UUID, which determines the field widths and units.
    /// - Returns: The minimum, maximum, and minimum increment fields.
    static func decode(_ data: Data, uuid: CBUUID) -> [DecodedField] {
        var reader = ByteReader(data)

        switch uuid {
        case GATTIdentifier.Characteristic.supportedSpeedRange:
            return scaledFields(
                &reader,
                unit: "km/h",
                scale: 0.01,
                readSigned: false
            )

        case GATTIdentifier.Characteristic.supportedInclinationRange:
            return scaledFields(
                &reader,
                unit: "%",
                scale: 0.1,
                readSigned: true
            )

        case GATTIdentifier.Characteristic.supportedResistanceLevelRange:
            return scaledFields(
                &reader,
                unit: "",
                scale: 0.1,
                readSigned: true
            )

        case GATTIdentifier.Characteristic.supportedPowerRange:
            return scaledFields(
                &reader,
                unit: "W",
                scale: 1,
                readSigned: true
            )

        case GATTIdentifier.Characteristic.supportedHeartRateRange:
            guard let minimum = reader.uint8(), let maximum = reader.uint8(), let increment = reader.uint8() else {
                return [DecodedField(label: "Error", value: "Payload too short for a heart rate range")]
            }
            return [
                .measurement("Minimum Heart Rate", minimum, unit: "bpm"),
                .measurement("Maximum Heart Rate", maximum, unit: "bpm"),
                .measurement("Minimum Increment", increment, unit: "bpm")
            ]

        default:
            return [DecodedField(label: "Error", value: "Not a supported-range characteristic")]
        }
    }

    // MARK: - Private Helpers

    /// Reads a minimum, maximum, and minimum increment as 16-bit values and applies a scale factor.
    ///
    /// The minimum and maximum are signed for inclination, resistance, and power;
    /// the minimum increment is always unsigned.
    private static func scaledFields(
        _ reader: inout ByteReader,
        unit: String,
        scale: Double,
        readSigned: Bool
    ) -> [DecodedField] {
        func readBound() -> Double? {
            if readSigned {
                guard let value = reader.int16() else { return nil }
                return Double(value)
            }
            guard let value = reader.uint16() else { return nil }
            return Double(value)
        }

        guard let minimum = readBound(), let maximum = readBound(), let increment = reader.uint16() else {
            return [DecodedField(label: "Error", value: "Payload too short for a 6-byte range")]
        }

        let suffix = unit.isEmpty ? "" : " \(unit)"
        let decimals = scale < 0.1 ? 2 : (scale < 1 ? 1 : 0)

        func format(_ value: Double) -> String {
            String(format: "%.\(decimals)f%@", value * scale, suffix)
        }

        return [
            DecodedField(label: "Minimum", value: format(minimum)),
            DecodedField(label: "Maximum", value: format(maximum)),
            DecodedField(label: "Minimum Increment", value: format(Double(increment)))
        ]
    }
}
