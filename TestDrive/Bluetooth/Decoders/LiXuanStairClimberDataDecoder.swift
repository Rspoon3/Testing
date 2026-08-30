//
//  LiXuanStairClimberDataDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the non-conforming **Stair Climber Data** layout used by the LiXuan
/// `WLT5283M` controller found in STEPR machines.
///
/// The firmware declares flags `0x03FE` — every optional field present — which the
/// specification says must produce a 25-byte payload. It sends 23. Two deviations
/// account for the difference:
///
/// 1. Flag bit 4 claims Stride Count is present, but the field is never transmitted.
/// 2. Step Count is moved out of its specified slot (second) to fifth, after
///    Positive Elevation Gain, so Floors and Step Count are not adjacent.
///
/// Decoding this with the specification layout silently shifts every field after
/// Floors, which is how a 96-step workout came out as "Positive Elevation Gain:
/// 96 m" and an 88-second elapsed time came out as "Heart Rate: 88 bpm".
///
/// The layout below was verified byte-for-byte against the machine's own console:
/// STEPS 96, CALORIES 16, TIME 1:28, ALTITUDE 38 ft, PULSE 0, SPEED 0 with a peak
/// of 16.
enum LiXuanStairClimberDataDecoder {

    /// The total payload length this layout produces, including the 2-byte flags.
    static let payloadLength = 23

    /// The flags value the controller always reports.
    static let expectedFlags: UInt16 = 0x03FE

    // MARK: - Public Helpers

    /// Indicates whether a payload matches this vendor layout.
    ///
    /// The check is deliberately narrow — exact length and exact flags — so a
    /// firmware update that starts conforming falls back to the specification
    /// decoder rather than being mis-parsed by this one.
    /// - Parameters:
    ///   - data: The raw characteristic value.
    ///   - flags: The already-parsed flags field.
    /// - Returns: `true` when the vendor layout applies.
    static func matches(_ data: Data, flags: UInt16) -> Bool {
        data.count == payloadLength && flags == expectedFlags
    }

    /// Parses a payload into typed values.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The parsed sample, or `nil` when the payload is not this layout.
    static func parse(_ data: Data) -> LiXuanStairClimberSample? {
        var reader = ByteReader(data)

        guard let flags = reader.uint16(), matches(data, flags: flags) else { return nil }

        guard let floorsSlotRaw = reader.uint16(),
              let speedLevel = reader.uint16(),
              let averageStepRate = reader.uint16(),
              let elevationGainMetres = reader.uint16(),
              let stepCount = reader.uint16(),
              let totalEnergy = reader.uint16(),
              reader.uint16() != nil,               // Energy Per Hour, always 0xFFFF
              reader.uint8() != nil,                // Energy Per Minute, always 0xFF
              let heartRate = reader.uint8(),
              let metabolicEquivalentRaw = reader.uint8(),
              let elapsedSeconds = reader.uint16(),
              let remainingSeconds = reader.uint16() else {
            return nil
        }

        return LiXuanStairClimberSample(
            floorsSlotRaw: floorsSlotRaw,
            speedLevel: speedLevel,
            averageStepRate: averageStepRate,
            elevationGainMetres: elevationGainMetres,
            stepCount: stepCount,
            totalEnergyKilocalories: totalEnergy == 0xFFFF ? nil : totalEnergy,
            heartRate: heartRate,
            metabolicEquivalentRaw: metabolicEquivalentRaw,
            elapsedSeconds: elapsedSeconds,
            remainingSeconds: remainingSeconds
        )
    }

    /// Decodes a payload using the verified LiXuan layout.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The decoded fields.
    static func decode(_ data: Data) -> [DecodedField] {
        var flagsReader = ByteReader(data)

        guard let flags = flagsReader.uint16(), let sample = parse(data) else {
            return [DecodedField(label: "Error", value: "Payload is not the LiXuan layout")]
        }

        var fields: [DecodedField] = [
            DecodedField(
                label: "Layout",
                value: "LiXuan WLT5283M (non-standard)",
                detail: "23 bytes where FTMS 1.0 specifies 25 for flags 0x03FE"
            ),
            DecodedField(
                label: "Flags",
                value: BitFieldFormatter
                    .setFlags(in: flags, names: StairClimberDataDecoder.flagNames)
                    .joined(separator: ", "),
                detail: "0x\(String(format: "%04X", flags)) — \(BitFieldFormatter.binaryDescription(flags))"
            )
        ]

        // Floors are not reported as a number; the value is derived from the
        // countdown in byte 2. See LiXuanStairClimberSample.floors.
        if let floors = sample.floors {
            fields.append(DecodedField(
                label: "Floors",
                value: "\(floors) floors",
                detail: "derived: byte 2 counts down from \(LiXuanStairClimberSample.floorCounterBase), now \(sample.floorsSlotRaw & 0x00FF)"
            ))
        } else {
            fields.append(DecodedField(
                label: "Floors (raw slot)",
                value: "0x\(String(format: "%04X", sample.floorsSlotRaw)) — unrecognised",
                detail: "expected high byte 0x10 with a low byte at or below \(LiXuanStairClimberSample.floorCounterBase)"
            ))
        }

        // Occupies the Step Per Minute slot but carries the machine's own SPEED
        // level, matching the 1–25 range from Supported Resistance Level Range.
        fields.append(DecodedField(
            label: "Current Speed",
            value: "\(sample.speedLevel)",
            detail: "machine's SPEED level, 0–25; sits in the FTMS Step Per Minute slot"
        ))

        fields.append(DecodedField(
            label: "Average Step Rate",
            value: sample.averageStepRate == 0
                ? "0 step/min (never populated by this firmware)"
                : "\(sample.averageStepRate) step/min"
        ))

        // Truncated by the firmware to whole metres, so converting back to feet
        // lands a foot or two under the console, which keeps finer precision.
        fields.append(DecodedField(
            label: "Positive Elevation Gain",
            value: "\(sample.elevationGainMetres) m",
            detail: String(format: "~%.0f ft; whole metres only, so slightly under the console", Double(sample.elevationGainMetres) * 3.28084)
        ))

        fields.append(.measurement("Step Count", sample.stepCount, unit: "steps"))

        fields.append(DecodedField(
            label: "Total Energy",
            value: sample.totalEnergyKilocalories.map { "\($0) kcal" } ?? "Not available"
        ))

        fields.append(DecodedField(label: "Energy Per Hour", value: "Not available"))
        fields.append(DecodedField(label: "Energy Per Minute", value: "Not available"))
        fields.append(.measurement("Heart Rate", sample.heartRate, unit: "bpm"))

        fields.append(DecodedField(
            label: "Metabolic Equivalent",
            value: String(format: "%.1f METs", Double(sample.metabolicEquivalentRaw) * 0.1)
        ))

        fields.append(.duration("Elapsed Time", seconds: Int(sample.elapsedSeconds)))
        fields.append(.duration("Remaining Time", seconds: Int(sample.remainingSeconds)))

        fields.append(DecodedField(
            label: "Stride Count",
            value: "Not transmitted",
            detail: "flag bit 4 claims it is present, but the firmware omits the field"
        ))

        return fields
    }
}
