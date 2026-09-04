//
//  FitShowTreadmillDataDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the framed protocol spoken by FitShow-app treadmills, such as the
/// maksone `SL-Z01` (Ningbo Kangruida `AMA005726`, also sold as FUIMLY).
///
/// FitShow machines do not implement the Fitness Machine Service. They expose one
/// vendor service — `FFF0`, `FFE0`, or `AE00` depending on the firmware — with a
/// write characteristic and a notify characteristic, and stream ``FitShowFrame``
/// packets on the latter. Fields are little-endian, unlike the big-endian PitPat
/// protocol handled by ``PitPatTreadmillDataDecoder``.
///
/// The layouts below come from the `qdomyos-zwift` FitShow driver. Offsets are into
/// the frame payload, which begins at raw byte 3 — immediately after the header,
/// command, and parameter bytes.
///
/// **System Status (`0x51`), parameter `1`, `3`, `4`, or `10`** — the running
/// telemetry frame, and the one worth watching:
///
/// | Payload offset | Size | Field |
/// | --- | --- | --- |
/// | 0 | 1 | Speed, tenths |
/// | 1 | 1 | Incline, signed |
/// | 2 | 2 | Elapsed time, seconds |
/// | 4 | 2 | Distance, tenths |
/// | 6 | 2 | Calories |
/// | 8 | 2 | Step count |
/// | 10 | 1 | Heart rate |
enum FitShowTreadmillDataDecoder {

    /// The parameter bytes on a System Status frame that carry full telemetry.
    static let telemetryParameters: Set<UInt8> = [
        FitShowTreadmillSample.Status.ended.rawValue,
        FitShowTreadmillSample.Status.running.rawValue,
        FitShowTreadmillSample.Status.stopped.rawValue,
        FitShowTreadmillSample.Status.paused.rawValue
    ]

    /// The payload bytes a telemetry frame needs before it can be parsed.
    static let telemetryPayloadLength = 11

    /// Exact kilometres per mile, for showing both readings of an unlabelled speed.
    static let kilometresPerMile = 1.609344

    // MARK: - Public Helpers

    /// Parses the running telemetry from a System Status frame.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The parsed sample, or `nil` when the value is not a telemetry frame.
    static func parse(_ data: Data) -> FitShowTreadmillSample? {
        guard let frame = FitShowFrame(data), frame.isChecksumValid else { return nil }
        return parse(frame)
    }

    /// Parses the running telemetry from an already-framed packet.
    /// - Parameter frame: The validated frame.
    /// - Returns: The parsed sample, or `nil` when the frame is not telemetry.
    static func parse(_ frame: FitShowFrame) -> FitShowTreadmillSample? {
        guard frame.family == .status,
              let parameter = frame.parameter,
              telemetryParameters.contains(parameter),
              let status = FitShowTreadmillSample.Status(rawValue: parameter),
              frame.payload.count >= telemetryPayloadLength else {
            return nil
        }

        var reader = ByteReader(frame.payload)

        guard let speedTenths = reader.uint8(),
              let incline = reader.int8(),
              let elapsedSeconds = reader.uint16(),
              let distanceTenths = reader.uint16(),
              let calories = reader.uint16(),
              let steps = reader.uint16(),
              let heartRate = reader.uint8() else {
            return nil
        }

        return FitShowTreadmillSample(
            status: status,
            speedTenths: speedTenths,
            incline: incline,
            elapsedSeconds: elapsedSeconds,
            distanceTenths: distanceTenths,
            calories: calories,
            steps: steps,
            heartRate: heartRate
        )
    }

    /// Decodes a value received on a FitShow notify characteristic.
    ///
    /// Returns `nil` — rather than an error field — when the value is not a FitShow
    /// frame at all, so the caller can fall back to a hex dump. `FFF1` and `FFE4`
    /// are generic vendor UUIDs, and a device that merely happens to use one should
    /// not have its data presented as a misparsed treadmill packet.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The decoded fields, or `nil` when the framing does not match.
    static func decode(_ data: Data) -> [DecodedField]? {
        guard let frame = FitShowFrame(data) else { return nil }

        var fields: [DecodedField] = [
            DecodedField(
                label: "Layout",
                value: "FitShow \(frame.family.name) (vendor protocol)",
                detail: "little-endian, \(data.count) bytes; not the Fitness Machine Service"
            ),
            DecodedField(
                label: "Frame",
                value: frame.isChecksumValid
                    ? "Valid — command 0x\(hex(frame.command))\(frame.parameter.map { ", parameter \($0)" } ?? "")"
                    : "Checksum mismatch",
                detail: frame.isChecksumValid
                    ? "header 0x02, footer 0x03, XOR checksum 0x\(hex(frame.transmittedChecksum)) verified"
                    : "transmitted 0x\(hex(frame.transmittedChecksum)), computed 0x\(hex(frame.computedChecksum))"
            )
        ]

        guard frame.isChecksumValid else {
            fields.append(DecodedField(label: "Payload", value: data.hexDescription))
            return fields
        }

        switch frame.family {
        case .status:
            fields.append(contentsOf: statusFields(frame))
        case .info:
            fields.append(contentsOf: infoFields(frame))
        case .data:
            fields.append(contentsOf: sessionDataFields(frame))
        case .control:
            fields.append(contentsOf: controlFields(frame))
        case .key:
            fields.append(DecodedField(
                label: "Console Key",
                value: frame.parameter.map { "Key \($0)" } ?? "Unknown",
                detail: "a button was pressed on the machine's own panel"
            ))
        case .unknown:
            fields.append(DecodedField(
                label: "Payload",
                value: frame.payload.isEmpty ? "Empty" : frame.payload.hexDescription,
                detail: "command 0x\(hex(frame.command)) has no known meaning"
            ))
        }

        return fields
    }

    // MARK: - Private Helpers

    /// Fields for a System Status frame.
    private static func statusFields(_ frame: FitShowFrame) -> [DecodedField] {
        guard let parameter = frame.parameter else { return [] }

        let statusName = FitShowTreadmillSample.Status(rawValue: parameter)?.name ?? "Unknown (\(parameter))"
        var fields = [DecodedField(label: "Status", value: statusName, detail: "parameter byte \(parameter)")]

        guard let sample = parse(frame) else {
            // A Starting frame carries only the countdown; the rest carry nothing.
            if parameter == FitShowTreadmillSample.Status.starting.rawValue,
               let countdown = frame.payload.first {
                fields.append(.measurement("Countdown", countdown, unit: "s"))
            } else if !frame.payload.isEmpty {
                fields.append(DecodedField(
                    label: "Payload",
                    value: frame.payload.hexDescription,
                    detail: "too short for a telemetry frame (\(frame.payload.count) of \(telemetryPayloadLength) bytes)"
                ))
            }
            return fields
        }

        fields.append(DecodedField(
            label: "Current Speed",
            value: String(format: "%.1f", sample.speed),
            detail: unitAmbiguityDetail(sample.speed, metricUnit: "km/h", imperialUnit: "mph")
        ))

        fields.append(DecodedField(
            label: "Incline",
            value: "\(sample.incline)",
            detail: "signed; a machine without incline hardware always reports 0"
        ))

        fields.append(.duration("Elapsed Time", seconds: Int(sample.elapsedSeconds)))

        fields.append(DecodedField(
            label: "Total Distance",
            value: String(format: "%.1f", sample.distance),
            detail: unitAmbiguityDetail(sample.distance, metricUnit: "km", imperialUnit: "mi")
        ))

        fields.append(.measurement("Total Energy", sample.calories, unit: "kcal"))
        fields.append(.measurement("Step Count", sample.steps, unit: "steps"))

        fields.append(DecodedField(
            label: "Heart Rate",
            value: sample.hasHeartRate ? "\(sample.heartRate) bpm" : "Not detected",
            detail: sample.hasHeartRate ? nil : "0 means no strap paired, not a reading of zero"
        ))

        return fields
    }

    /// Fields for a System Info frame, which reports the machine's capabilities.
    private static func infoFields(_ frame: FitShowFrame) -> [DecodedField] {
        var reader = ByteReader(frame.payload)

        switch frame.parameter {
        case 0: // Model
            guard let high = reader.uint8(), let low = reader.uint16() else { return [] }
            return [DecodedField(
                label: "Device ID",
                value: "\(hex(high))-\(String(format: "%04X", low))",
                detail: "the identifier the FitShow app uses to look up this model"
            )]

        case 1: // Factory date
            guard let year = reader.uint8(), let month = reader.uint8(), let day = reader.uint8() else { return [] }
            return [DecodedField(
                label: "Factory Date",
                value: String(format: "%04d-%02d-%02d", Int(year) + 2000, month, day),
                detail: "year byte is an offset from 2000"
            )]

        case 2: // Speed range
            guard let maximum = reader.uint8(), let minimum = reader.uint8() else { return [] }
            var fields = [DecodedField(
                label: "Speed Range",
                value: String(format: "%.1f – %.1f", Double(minimum) / 10, Double(maximum) / 10),
                detail: "tenths; unit unlabelled, same ambiguity as the status frame"
            )]
            if let unit = reader.uint8() {
                fields.append(DecodedField(
                    label: "Unit Flag",
                    value: "\(unit)",
                    detail: "vendor unit selector; meaning not established"
                ))
            }
            return fields

        case 3: // Incline range
            guard let maximum = reader.uint8(), let minimum = reader.uint8() else {
                return [DecodedField(
                    label: "Incline",
                    value: "Not supported",
                    detail: "the machine returned a short frame for this query"
                )]
            }
            var fields = [DecodedField(label: "Incline Range", value: "\(minimum) – \(maximum)")]
            if let capabilities = reader.uint8() {
                fields.append(DecodedField(
                    label: "Supports Pause",
                    value: capabilities & 0x02 != 0 ? "Yes" : "No",
                    detail: "bit 1 of 0x\(hex(capabilities))"
                ))
            }
            return fields

        case 4: // Lifetime total
            guard let total = reader.uint32() else { return [] }
            return [.measurement("Lifetime Distance", total, unit: "(machine units)")]

        case 5: // Combined capabilities
            guard let maximumSpeed = reader.uint8(),
                  let minimumSpeed = reader.uint8(),
                  let maximumIncline = reader.uint8(),
                  let minimumIncline = reader.uint8(),
                  let supportsHeartRateControl = reader.uint8(),
                  let countdown = reader.uint8() else {
                return []
            }
            return [
                DecodedField(
                    label: "Speed Range",
                    value: String(format: "%.1f – %.1f", Double(minimumSpeed) / 10, Double(maximumSpeed) / 10)
                ),
                DecodedField(label: "Incline Range", value: "\(minimumIncline) – \(maximumIncline)"),
                DecodedField(label: "Heart Rate Control", value: supportsHeartRateControl != 0 ? "Supported" : "Not supported"),
                .measurement("Start Countdown", countdown, unit: "s")
            ]

        default:
            return [DecodedField(
                label: "Payload",
                value: frame.payload.isEmpty ? "Empty" : frame.payload.hexDescription,
                detail: "System Info parameter \(frame.parameter.map(String.init) ?? "?") is not documented"
            )]
        }
    }

    /// Fields for a System Data frame, which reports session totals and the mode.
    private static func sessionDataFields(_ frame: FitShowFrame) -> [DecodedField] {
        var reader = ByteReader(frame.payload)

        switch frame.parameter {
        case 0: // Sport totals
            guard let elapsedSeconds = reader.uint16(),
                  let distanceTenths = reader.uint16(),
                  let calories = reader.uint16(),
                  let steps = reader.uint16() else {
                return []
            }
            return [
                .duration("Elapsed Time", seconds: Int(elapsedSeconds)),
                DecodedField(
                    label: "Total Distance",
                    value: String(format: "%.1f", Double(distanceTenths) / 10),
                    detail: unitAmbiguityDetail(Double(distanceTenths) / 10, metricUnit: "km", imperialUnit: "mi")
                ),
                .measurement("Total Energy", calories, unit: "kcal"),
                .measurement("Step Count", steps, unit: "steps")
            ]

        case 1: // Session identity and mode
            guard let userID = reader.uint32(),
                  let sportID = reader.uint32(),
                  let mode = reader.uint8() else {
                return []
            }
            var fields = [
                DecodedField(label: "User ID", value: "\(userID)"),
                DecodedField(label: "Sport ID", value: "\(sportID)"),
                DecodedField(label: "Workout Mode", value: modeName(mode), detail: "mode byte \(mode)")
            ]
            reader.skip(1) // program number, only meaningful in Programs mode
            if let target = reader.uint16() {
                fields.append(DecodedField(
                    label: "Mode Target",
                    value: "\(target)",
                    detail: "interpreted per the workout mode: seconds, distance, or tenths of a kcal"
                ))
            }
            return fields

        default:
            return [DecodedField(
                label: "Payload",
                value: frame.payload.isEmpty ? "Empty" : frame.payload.hexDescription,
                detail: "System Data parameter \(frame.parameter.map(String.init) ?? "?") is not documented"
            )]
        }
    }

    /// Fields for a System Control acknowledgement.
    private static func controlFields(_ frame: FitShowFrame) -> [DecodedField] {
        var fields = [DecodedField(
            label: "Control Acknowledged",
            value: controlName(frame.parameter),
            detail: frame.parameter.map { "parameter byte \($0)" }
        )]

        var reader = ByteReader(frame.payload)
        if let speedTenths = reader.uint8() {
            fields.append(DecodedField(
                label: "Acknowledged Speed",
                value: String(format: "%.1f", Double(speedTenths) / 10)
            ))
        }
        if let incline = reader.int8() {
            fields.append(DecodedField(label: "Acknowledged Incline", value: "\(incline)"))
        }

        return fields
    }

    /// The name of a workout mode byte.
    private static func modeName(_ mode: UInt8) -> String {
        switch mode {
        case 0: "Normal"
        case 1: "Timed"
        case 2: "Distance"
        case 3: "Calorie"
        case 4: "Steps"
        case 5: "Programs"
        case 6: "Match"
        default: "Unknown (\(mode))"
        }
    }

    /// The name of a control parameter byte.
    private static func controlName(_ parameter: UInt8?) -> String {
        switch parameter {
        case 0: "User"
        case 1: "Ready / Start"
        case 2: "Set target / Run"
        case 3: "Stop"
        case 6: "Pause"
        case .some(let other): "Unknown (\(other))"
        case .none: "Unknown"
        }
    }

    /// Renders both unit readings of a value the protocol does not label.
    private static func unitAmbiguityDetail(_ value: Double, metricUnit: String, imperialUnit: String) -> String {
        String(
            format: "%.1f %@ if metric, or %.1f %@ (= %.1f %@) if imperial — confirm against the console",
            value, metricUnit,
            value, imperialUnit,
            value * kilometresPerMile, metricUnit
        )
    }

    /// A two-digit uppercase hex rendering of a byte.
    private static func hex(_ byte: UInt8) -> String {
        String(format: "%02X", byte)
    }
}
