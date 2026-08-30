//
//  CrossTrainerDataDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the Fitness Machine Service **Cross Trainer Data** characteristic (`0x2ACE`).
///
/// Included because stair machines with a stride-based motion sometimes classify
/// themselves as a cross trainer rather than a stair climber.
enum CrossTrainerDataDecoder {

    /// The flag bits of the Cross Trainer Data characteristic, in specification order.
    static let flagNames = [
        "More Data",
        "Average Speed present",
        "Total Distance present",
        "Step Count present",
        "Stride Count present",
        "Elevation Gain present",
        "Inclination and Ramp Angle present",
        "Resistance Level present",
        "Instantaneous Power present",
        "Average Power present",
        "Expended Energy present",
        "Heart Rate present",
        "Metabolic Equivalent present",
        "Elapsed Time present",
        "Remaining Time present",
        "Movement Direction: backward"
    ]

    // MARK: - Public Helpers

    /// Decodes a Cross Trainer Data payload.
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
            ),
            DecodedField(
                label: "Movement Direction",
                value: flags & 0x8000 != 0 ? "Backward" : "Forward"
            )
        ]

        if flags & 0x0001 == 0, let speed = reader.uint16() {
            fields.append(DecodedField(
                label: "Instantaneous Speed",
                value: String(format: "%.2f km/h", Double(speed) * 0.01)
            ))
        }

        if flags & 0x0002 != 0, let averageSpeed = reader.uint16() {
            fields.append(DecodedField(
                label: "Average Speed",
                value: String(format: "%.2f km/h", Double(averageSpeed) * 0.01)
            ))
        }

        if flags & 0x0004 != 0, let totalDistance = reader.uint24() {
            fields.append(.measurement("Total Distance", totalDistance, unit: "m"))
        }

        if flags & 0x0008 != 0 {
            if let stepsPerMinute = reader.uint16() {
                fields.append(.measurement("Step Per Minute", stepsPerMinute, unit: "step/min"))
            }
            if let averageStepRate = reader.uint16() {
                fields.append(.measurement("Average Step Rate", averageStepRate, unit: "step/min"))
            }
        }

        if flags & 0x0010 != 0, let strideCount = reader.uint16() {
            fields.append(.measurement("Stride Count", strideCount, unit: "strides"))
        }

        if flags & 0x0020 != 0 {
            if let positiveGain = reader.uint16() {
                fields.append(.measurement("Positive Elevation Gain", positiveGain, unit: "m"))
            }
            if let negativeGain = reader.uint16() {
                fields.append(.measurement("Negative Elevation Gain", negativeGain, unit: "m"))
            }
        }

        if flags & 0x0040 != 0 {
            if let inclination = reader.int16() {
                fields.append(DecodedField(
                    label: "Inclination",
                    value: String(format: "%.1f %%", Double(inclination) * 0.1)
                ))
            }
            if let rampAngle = reader.int16() {
                fields.append(DecodedField(
                    label: "Ramp Angle Setting",
                    value: String(format: "%.1f°", Double(rampAngle) * 0.1)
                ))
            }
        }

        if flags & 0x0080 != 0, let resistance = reader.int16() {
            fields.append(DecodedField(
                label: "Resistance Level",
                value: String(format: "%.1f", Double(resistance) * 0.1),
                detail: "raw \(resistance)"
            ))
        }

        if flags & 0x0100 != 0, let power = reader.int16() {
            fields.append(.measurement("Instantaneous Power", power, unit: "W"))
        }

        if flags & 0x0200 != 0, let averagePower = reader.int16() {
            fields.append(.measurement("Average Power", averagePower, unit: "W"))
        }

        if flags & 0x0400 != 0 {
            fields.append(contentsOf: ExpendedEnergyDecoder.decode(from: &reader))
        }

        if flags & 0x0800 != 0, let heartRate = reader.uint8() {
            fields.append(.measurement("Heart Rate", heartRate, unit: "bpm"))
        }

        if flags & 0x1000 != 0, let metabolicEquivalent = reader.uint8() {
            fields.append(DecodedField(
                label: "Metabolic Equivalent",
                value: String(format: "%.1f METs", Double(metabolicEquivalent) * 0.1)
            ))
        }

        if flags & 0x2000 != 0, let elapsedTime = reader.uint16() {
            fields.append(.duration("Elapsed Time", seconds: Int(elapsedTime)))
        }

        if flags & 0x4000 != 0, let remainingTime = reader.uint16() {
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
