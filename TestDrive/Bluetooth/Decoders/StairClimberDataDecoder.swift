//
//  StairClimberDataDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the Fitness Machine Service **Stair Climber Data** characteristic (`0x2AD0`).
///
/// Field order and presence follow the FTMS 1.0 specification. Note the inverted
/// "More Data" flag: bit 0 is *clear* when the Floors and Step Count fields are
/// present, which is the opposite of every other flag in the packet.
///
/// The raw bytes are always surfaced alongside the decode in the UI so a machine
/// with a non-conforming layout can be spotted rather than silently mis-read.
enum StairClimberDataDecoder {

    /// The flag bits of the Stair Climber Data characteristic, in specification order.
    static let flagNames = [
        "More Data",
        "Step Per Minute present",
        "Average Step Rate present",
        "Positive Elevation Gain present",
        "Stride Count present",
        "Expended Energy present",
        "Heart Rate present",
        "Metabolic Equivalent present",
        "Elapsed Time present",
        "Remaining Time present"
    ]

    // MARK: - Public Helpers

    /// The payload length the specification requires for a given flags value.
    /// - Parameter flags: The flags field.
    /// - Returns: The expected total byte count, including the flags themselves.
    static func expectedPayloadLength(forFlags flags: UInt16) -> Int? {
        var length = 2
        if flags & 0x0001 == 0 { length += 4 }   // Floors + Step Count
        if flags & 0x0002 != 0 { length += 2 }   // Step Per Minute
        if flags & 0x0004 != 0 { length += 2 }   // Average Step Rate
        if flags & 0x0008 != 0 { length += 2 }   // Positive Elevation Gain
        if flags & 0x0010 != 0 { length += 2 }   // Stride Count
        if flags & 0x0020 != 0 { length += 5 }   // Expended Energy block
        if flags & 0x0040 != 0 { length += 1 }   // Heart Rate
        if flags & 0x0080 != 0 { length += 1 }   // Metabolic Equivalent
        if flags & 0x0100 != 0 { length += 2 }   // Elapsed Time
        if flags & 0x0200 != 0 { length += 2 }   // Remaining Time
        return length
    }

    /// Decodes a Stair Climber Data payload.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The decoded fields, or a single diagnostic field when the payload is too short.
    static func decode(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)

        guard let flags = reader.uint16() else {
            return [DecodedField(label: "Error", value: "Payload too short for the 2-byte flags field")]
        }

        // Some controllers set every presence flag but ship a shorter, re-ordered
        // payload. Parsing those with the specification layout shifts every field
        // after Floors, so they are routed to a layout-specific decoder instead.
        if LiXuanStairClimberDataDecoder.matches(data, flags: flags) {
            return LiXuanStairClimberDataDecoder.decode(data)
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

        if flags & 0x0010 != 0, let strideCount = reader.uint16() {
            fields.append(.measurement("Stride Count", strideCount, unit: "strides"))
        }

        if flags & 0x0020 != 0 {
            fields.append(contentsOf: ExpendedEnergyDecoder.decode(from: &reader))
        }

        if flags & 0x0040 != 0, let heartRate = reader.uint8() {
            fields.append(.measurement("Heart Rate", heartRate, unit: "bpm"))
        }

        if flags & 0x0080 != 0, let metabolicEquivalent = reader.uint8() {
            fields.append(DecodedField(
                label: "Metabolic Equivalent",
                value: String(format: "%.1f METs", Double(metabolicEquivalent) * 0.1)
            ))
        }

        if flags & 0x0100 != 0, let elapsedTime = reader.uint16() {
            fields.append(.duration("Elapsed Time", seconds: Int(elapsedTime)))
        }

        if flags & 0x0200 != 0, let remainingTime = reader.uint16() {
            fields.append(.duration("Remaining Time", seconds: Int(remainingTime)))
        }

        if reader.remainingByteCount > 0 {
            fields.append(DecodedField(
                label: "Undecoded Trailing Bytes",
                value: "\(reader.remainingByteCount) byte(s)",
                detail: reader.remainingBytes.hexDescription
            ))
        }

        // Running out of bytes mid-decode means the flags promised fields the
        // firmware did not send, so every field after the shortfall is suspect.
        if let expectedLength = Self.expectedPayloadLength(forFlags: flags), data.count < expectedLength {
            fields.append(DecodedField(
                label: "⚠️ Layout Mismatch",
                value: "Flags promise \(expectedLength) bytes, received \(data.count)",
                detail: "Fields above may be shifted. Trust the raw bytes."
            ))
        }

        return fields
    }
}
