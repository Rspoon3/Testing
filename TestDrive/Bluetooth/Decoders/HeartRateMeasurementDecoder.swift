//
//  HeartRateMeasurementDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the **Heart Rate Measurement** characteristic (`0x2A37`), which a
/// fitness machine may re-broadcast when a chest strap is paired to the machine
/// rather than to the phone.
enum HeartRateMeasurementDecoder {

    // MARK: - Public Helpers

    /// Decodes a Heart Rate Measurement payload.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The heart rate, sensor contact state, and any optional fields.
    static func decode(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)

        guard let flags = reader.uint8() else {
            return [DecodedField(label: "Error", value: "Empty heart rate payload")]
        }

        let usesWideFormat = flags & 0x01 != 0
        var fields: [DecodedField] = []

        if usesWideFormat {
            if let heartRate = reader.uint16() {
                fields.append(.measurement("Heart Rate", heartRate, unit: "bpm"))
            }
        } else if let heartRate = reader.uint8() {
            fields.append(.measurement("Heart Rate", heartRate, unit: "bpm"))
        }

        let sensorContact = switch (flags >> 1) & 0x03 {
        case 0b10: "Supported, no contact"
        case 0b11: "Supported, contact detected"
        default: "Not supported"
        }
        fields.append(DecodedField(label: "Sensor Contact", value: sensorContact))

        if flags & 0x08 != 0, let energyExpended = reader.uint16() {
            fields.append(.measurement("Energy Expended", energyExpended, unit: "kJ"))
        }

        if flags & 0x10 != 0 {
            var intervals: [String] = []
            while let interval = reader.uint16() {
                intervals.append(String(format: "%.0f ms", Double(interval) / 1024 * 1000))
            }
            if !intervals.isEmpty {
                fields.append(DecodedField(
                    label: "RR Intervals",
                    value: intervals.joined(separator: ", "),
                    detail: "resolution 1/1024 s"
                ))
            }
        }

        fields.append(DecodedField(
            label: "Flags",
            value: usesWideFormat ? "16-bit heart rate format" : "8-bit heart rate format",
            detail: "0x\(String(format: "%02X", flags))"
        ))

        return fields
    }
}
