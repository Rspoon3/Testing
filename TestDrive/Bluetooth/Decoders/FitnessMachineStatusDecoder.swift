//
//  FitnessMachineStatusDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the **Fitness Machine Status** characteristic (`0x2ADA`), which notifies
/// clients when the machine starts, stops, pauses, or has a target changed.
enum FitnessMachineStatusDecoder {

    // MARK: - Public Helpers

    /// Decodes a Fitness Machine Status payload.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: The op code name plus any decoded parameters.
    static func decode(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)

        guard let opCode = reader.uint8() else {
            return [DecodedField(label: "Error", value: "Empty status payload")]
        }

        var fields: [DecodedField] = [
            DecodedField(
                label: "Status",
                value: name(forOpCode: opCode),
                detail: "op code 0x\(String(format: "%02X", opCode))"
            )
        ]

        switch opCode {
        case 0x02:
            if let reason = reader.uint8() {
                let description = switch reason {
                case 0x01: "Stopped"
                case 0x02: "Paused"
                default: "Reserved (0x\(String(format: "%02X", reason)))"
                }
                fields.append(DecodedField(label: "Stop or Pause Reason", value: description))
            }
        case 0x05:
            if let speed = reader.uint16() {
                fields.append(DecodedField(label: "New Target Speed", value: String(format: "%.2f km/h", Double(speed) * 0.01)))
            }
        case 0x06:
            if let inclination = reader.int16() {
                fields.append(DecodedField(label: "New Target Inclination", value: String(format: "%.1f %%", Double(inclination) * 0.1)))
            }
        case 0x07:
            if let resistance = reader.uint8() {
                fields.append(DecodedField(label: "New Target Resistance Level", value: String(format: "%.1f", Double(resistance) * 0.1)))
            }
        case 0x08:
            if let power = reader.int16() {
                fields.append(.measurement("New Target Power", power, unit: "W"))
            }
        case 0x09:
            if let heartRate = reader.uint8() {
                fields.append(.measurement("New Target Heart Rate", heartRate, unit: "bpm"))
            }
        case 0x0A:
            if let energy = reader.uint16() {
                fields.append(.measurement("New Targeted Expended Energy", energy, unit: "kcal"))
            }
        case 0x0B:
            if let steps = reader.uint16() {
                fields.append(.measurement("New Targeted Number of Steps", steps, unit: "steps"))
            }
        case 0x0C:
            if let strides = reader.uint16() {
                fields.append(.measurement("New Targeted Number of Strides", strides, unit: "strides"))
            }
        case 0x0D:
            if let distance = reader.uint24() {
                fields.append(.measurement("New Targeted Distance", distance, unit: "m"))
            }
        case 0x0E:
            if let seconds = reader.uint16() {
                fields.append(.duration("New Targeted Training Time", seconds: Int(seconds)))
            }
        default:
            break
        }

        if reader.remainingByteCount > 0 {
            fields.append(DecodedField(
                label: "Parameters",
                value: "\(reader.remainingByteCount) byte(s)",
                detail: reader.remainingBytes.hexDescription
            ))
        }

        return fields
    }

    // MARK: - Private Helpers

    /// Maps a status op code to its specification name.
    private static func name(forOpCode opCode: UInt8) -> String {
        switch opCode {
        case 0x01: "Reset"
        case 0x02: "Stopped or Paused by the User"
        case 0x03: "Stopped by Safety Key"
        case 0x04: "Started or Resumed by the User"
        case 0x05: "Target Speed Changed"
        case 0x06: "Target Incline Changed"
        case 0x07: "Target Resistance Level Changed"
        case 0x08: "Target Power Changed"
        case 0x09: "Target Heart Rate Changed"
        case 0x0A: "Targeted Expended Energy Changed"
        case 0x0B: "Targeted Number of Steps Changed"
        case 0x0C: "Targeted Number of Strides Changed"
        case 0x0D: "Targeted Distance Changed"
        case 0x0E: "Targeted Training Time Changed"
        case 0x0F: "Targeted Time in Two Heart Rate Zones Changed"
        case 0x10: "Targeted Time in Three Heart Rate Zones Changed"
        case 0x11: "Targeted Time in Five Heart Rate Zones Changed"
        case 0x12: "Indoor Bike Simulation Parameters Changed"
        case 0x13: "Wheel Circumference Changed"
        case 0x14: "Spin Down Status"
        case 0x15: "Targeted Cadence Changed"
        case 0xFF: "Control Permission Lost"
        default: "Unknown or vendor-specific"
        }
    }
}
