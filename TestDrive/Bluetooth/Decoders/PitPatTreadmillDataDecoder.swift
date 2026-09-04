//
//  PitPatTreadmillDataDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the proprietary state notification sent by PitPat-app treadmills and
/// walking pads, such as the SupeRun `BA10-B`.
///
/// These machines do not implement the Fitness Machine Service. Instead they expose
/// a single vendor service (`FBA0`) with a command characteristic (`FBA1`) and a
/// notifying state characteristic (`FBA2`), and speak a framed protocol that is
/// big-endian throughout — the opposite of every GATT specification field this app
/// otherwise decodes.
///
/// The layout below comes from the community reverse-engineering effort behind the
/// `pacekeeper` and `HomeAssistantWalkingPad` projects. Field offsets, in a payload
/// of at least ``minimumPayloadLength`` bytes:
///
/// | Offset | Size | Field |
/// | --- | --- | --- |
/// | 3 | 2 | Current speed, thousandths of km/h |
/// | 5 | 2 | Target speed, thousandths of km/h |
/// | 7 | 4 | Distance, metres |
/// | 14 | 4 | Step count |
/// | 18 | 2 | Calories |
/// | 20 | 4 | Elapsed time, milliseconds |
/// | 25 | 1 | Firmware version |
/// | 26 | 1 | Status flags |
/// | 27 | 2 | Maximum speed, thousandths of km/h |
///
/// Bytes 0–2, 11–13, 24, and anything past 28 are not understood yet, so they are
/// surfaced as raw hex rather than quietly dropped.
enum PitPatTreadmillDataDecoder {

    /// The shortest payload that is trusted as a state frame.
    ///
    /// Shorter notifications are rejected outright rather than parsed from a
    /// truncated buffer, matching the reference implementation.
    static let minimumPayloadLength = 31

    /// Exact kilometres per mile, for showing the values the console displays.
    static let kilometresPerMile = 1.609344

    /// The bit in the status flags that marks the console as displaying imperial units.
    static let imperialFlagMask: UInt8 = 0x80

    /// The two bits in the status flags that encode the belt state.
    static let statusFlagMask: UInt8 = 0x18

    // MARK: - Public Helpers

    /// Indicates whether a payload is long enough to be a state frame.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: `true` when the payload can be parsed.
    static func matches(_ data: Data) -> Bool {
        data.count >= minimumPayloadLength
    }

    /// Parses a state notification into typed values.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The parsed sample, or `nil` when the payload is too short.
    static func parse(_ data: Data) -> PitPatTreadmillSample? {
        guard matches(data) else { return nil }

        var reader = ByteReader(data)

        guard reader.skip(3),                                   // bytes 0–2, framing
              let currentSpeed = reader.uint16BigEndian(),      // 3–4
              let targetSpeed = reader.uint16BigEndian(),       // 5–6
              let distanceMetres = reader.uint32BigEndian(),    // 7–10
              reader.skip(3),                                   // 11–13, unknown
              let steps = reader.uint32BigEndian(),             // 14–17
              let calories = reader.uint16BigEndian(),          // 18–19
              let durationMilliseconds = reader.uint32BigEndian(), // 20–23
              reader.skip(1),                                   // 24, unknown
              let firmwareVersion = reader.uint8(),             // 25
              let flags = reader.uint8(),                       // 26
              let maximumSpeed = reader.uint16BigEndian() else { // 27–28
            return nil
        }

        return PitPatTreadmillSample(
            status: status(forFlags: flags),
            speedKilometresPerHour: Double(currentSpeed) / 1000,
            targetSpeedKilometresPerHour: Double(targetSpeed) / 1000,
            maximumSpeedKilometresPerHour: Double(maximumSpeed) / 1000,
            distanceKilometres: Double(distanceMetres) / 1000,
            calories: calories,
            steps: steps,
            elapsedSeconds: Int(durationMilliseconds / 1000),
            firmwareVersion: firmwareVersion,
            isImperialPanel: flags & imperialFlagMask != 0,
            statusFlags: flags
        )
    }

    /// Decodes a state notification into display fields.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The decoded fields.
    static func decode(_ data: Data) -> [DecodedField] {
        guard let sample = parse(data) else {
            return [DecodedField(
                label: "Error",
                value: "Payload is \(data.count) bytes; a PitPat state frame is at least \(minimumPayloadLength)",
                detail: data.hexDescription
            )]
        }

        var fields: [DecodedField] = [
            DecodedField(
                label: "Layout",
                value: "PitPat treadmill (vendor protocol)",
                detail: "big-endian, \(data.count) bytes; not the Fitness Machine Service"
            ),
            DecodedField(label: "Status", value: sample.status.rawValue,
                         detail: "flags 0x\(String(format: "%02X", sample.statusFlags)) — \(BitFieldFormatter.binaryDescription(sample.statusFlags))")
        ]

        fields.append(DecodedField(
            label: "Current Speed",
            value: String(format: "%.2f km/h", sample.speedKilometresPerHour),
            detail: String(format: "%.2f mph", sample.speedMilesPerHour)
        ))

        fields.append(DecodedField(
            label: "Target Speed",
            value: String(format: "%.2f km/h", sample.targetSpeedKilometresPerHour),
            detail: String(format: "%.2f mph — the speed the belt is ramping toward", sample.targetSpeedKilometresPerHour / kilometresPerMile)
        ))

        fields.append(DecodedField(
            label: "Maximum Speed",
            value: String(format: "%.2f km/h", sample.maximumSpeedKilometresPerHour),
            detail: String(format: "%.2f mph — highest speed this machine accepts", sample.maximumSpeedKilometresPerHour / kilometresPerMile)
        ))

        fields.append(DecodedField(
            label: "Total Distance",
            value: String(format: "%.3f km", sample.distanceKilometres),
            detail: String(format: "%.3f mi", sample.distanceMiles)
        ))

        fields.append(.measurement("Step Count", sample.steps, unit: "steps"))
        fields.append(.measurement("Total Energy", sample.calories, unit: "kcal"))
        fields.append(.duration("Elapsed Time", seconds: sample.elapsedSeconds))
        fields.append(.measurement("Firmware Version", sample.firmwareVersion))

        fields.append(DecodedField(
            label: "Console Units",
            value: sample.isImperialPanel ? "Imperial (mph/miles)" : "Metric (km/h/km)",
            detail: "display only — the machine always transmits metric"
        ))

        fields.append(DecodedField(
            label: "Undecoded Bytes",
            value: undecodedByteDescription(data),
            detail: "offsets 0–2, 11–13, 24, and 29 onward have no known meaning yet"
        ))

        return fields
    }

    // MARK: - Private Helpers

    /// Maps the belt-state bits in the status flags to a status.
    private static func status(forFlags flags: UInt8) -> PitPatTreadmillSample.Status {
        switch flags & statusFlagMask {
        case 0x18: .countdown
        case 0x08: .running
        case 0x10: .paused
        default: .stopped
        }
    }

    /// Renders the bytes with no known meaning, so a future session can spot one changing.
    private static func undecodedByteDescription(_ data: Data) -> String {
        let bytes = Array(data)
        var ranges: [(String, Range<Int>)] = [
            ("0–2", 0..<3),
            ("11–13", 11..<14),
            ("24", 24..<25)
        ]

        if bytes.count > 29 {
            ranges.append(("29–\(bytes.count - 1)", 29..<bytes.count))
        }

        return ranges
            .compactMap { label, range in
                guard range.upperBound <= bytes.count else { return nil }
                let hex = bytes[range].map { String(format: "%02X", $0) }.joined(separator: " ")
                return "[\(label)] \(hex)"
            }
            .joined(separator: "  ")
    }
}
