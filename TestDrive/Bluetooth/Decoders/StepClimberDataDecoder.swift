//
//  StepClimberDataDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the Fitness Machine Service **Step Climber Data** characteristic (`0x2ACF`).
///
/// This is the sibling of Stair Climber Data: same shape, but it has no Stride
/// Count field, so every flag from bit 4 upward shifts down by one position.
/// A stair machine's firmware may expose either characteristic, so the app
/// subscribes to both.
enum StepClimberDataDecoder {

    /// The flag bits of the Step Climber Data characteristic, in specification order.
    static let flagNames = [
        "More Data",
        "Step Per Minute present",
        "Average Step Rate present",
        "Positive Elevation Gain present",
        "Expended Energy present",
        "Heart Rate present",
        "Metabolic Equivalent present",
        "Elapsed Time present",
        "Remaining Time present"
    ]

    // MARK: - Public Helpers

    /// Decodes a Step Climber Data payload.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The decoded fields, or a single diagnostic field when the payload is too short.
    static func decode(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)

        guard let flags = reader.uint16() else {
            return [DecodedField(label: "Error", value: "Payload too short for the 2-byte flags field")]
        }

        var fields: [DecodedField] = [
            DecodedField(
                label: "Flags",
                value: BitFieldFormatter.setFlags(in: flags, names: flagNames).joined(separator: ", "),
                detail: "0x\(String(format: "%04X", flags)) — \(BitFieldFormatter.binaryDescription(flags))"
            )
        ]

        // Bit 0 clear means the cumulative Floors and Step Count fields are present.
        if flags & 0x0001 == 0 {
            if let floors = reader.uint16() {
                fields.append(.measurement("Floors", floors, unit: "floors"))
            }
            if let stepCount = reader.uint16() {
                fields.append(.measurement("Step Count", stepCount, unit: "steps"))
            }
        }

        if flags & 0x0002 != 0, let stepsPerMinute = reader.uint16() {
            fields.append(.measurement("Step Per Minute", stepsPerMinute, unit: "step/min"))
        }

        if flags & 0x0004 != 0, let averageStepRate = reader.uint16() {
            fields.append(.measurement("Average Step Rate", averageStepRate, unit: "step/min"))
        }

        if flags & 0x0008 != 0, let elevationGain = reader.uint16() {
            fields.append(.measurement("Positive Elevation Gain", elevationGain, unit: "m"))
        }

        if flags & 0x0010 != 0 {
            fields.append(contentsOf: ExpendedEnergyDecoder.decode(from: &reader))
        }

        if flags & 0x0020 != 0, let heartRate = reader.uint8() {
            fields.append(.measurement("Heart Rate", heartRate, unit: "bpm"))
        }

        if flags & 0x0040 != 0, let metabolicEquivalent = reader.uint8() {
            fields.append(DecodedField(
                label: "Metabolic Equivalent",
                value: String(format: "%.1f METs", Double(metabolicEquivalent) * 0.1)
            ))
        }

        if flags & 0x0080 != 0, let elapsedTime = reader.uint16() {
            fields.append(.duration("Elapsed Time", seconds: Int(elapsedTime)))
        }

        if flags & 0x0100 != 0, let remainingTime = reader.uint16() {
            fields.append(.duration("Remaining Time", seconds: Int(remainingTime)))
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
