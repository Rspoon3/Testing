//
//  TrainingStatusDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the **Training Status** characteristic (`0x2AD3`).
enum TrainingStatusDecoder {

    // MARK: - Public Helpers

    /// Decodes a Training Status payload.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The flags, the training status, and the optional status string.
    static func decode(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)

        guard let flags = reader.uint8(), let status = reader.uint8() else {
            return [DecodedField(label: "Error", value: "Payload too short for flags and status")]
        }

        var fields: [DecodedField] = [
            DecodedField(
                label: "Training Status",
                value: name(forStatus: status),
                detail: "0x\(String(format: "%02X", status))"
            ),
            DecodedField(
                label: "Flags",
                value: [
                    flags & 0x01 != 0 ? "Training Status String present" : nil,
                    flags & 0x02 != 0 ? "Extended String present" : nil
                ].compactMap(\.self).joined(separator: ", "),
                detail: "0x\(String(format: "%02X", flags))"
            )
        ]

        if flags & 0x01 != 0, let string = reader.utf8String(), !string.isEmpty {
            fields.append(DecodedField(label: "Training Status String", value: string))
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

    // MARK: - Private Helpers

    /// Maps a training status value to its specification name.
    private static func name(forStatus status: UInt8) -> String {
        switch status {
        case 0x00: "Other"
        case 0x01: "Idle"
        case 0x02: "Warming Up"
        case 0x03: "Low Intensity Interval"
        case 0x04: "High Intensity Interval"
        case 0x05: "Recovery Interval"
        case 0x06: "Isometric"
        case 0x07: "Heart Rate Control"
        case 0x08: "Fitness Test"
        case 0x09: "Speed Outside of Control Region — Low"
        case 0x0A: "Speed Outside of Control Region — High"
        case 0x0B: "Cool Down"
        case 0x0C: "Watt Control"
        case 0x0D: "Manual Mode (Quick Start)"
        case 0x0E: "Pre-Workout"
        case 0x0F: "Post-Workout"
        default: "Unknown or vendor-specific"
        }
    }
}
