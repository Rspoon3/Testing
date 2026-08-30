//
//  FitnessMachineFeatureDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the **Fitness Machine Feature** characteristic (`0x2ACC`).
///
/// This is the single most valuable read on an undocumented machine: two 32-bit
/// bit fields that declare exactly which metrics the machine can report and which
/// targets it will let a client set.
enum FitnessMachineFeatureDecoder {

    /// Bit names for the first 32-bit field, which declares reportable metrics.
    static let featureNames = [
        "Average Speed",
        "Cadence",
        "Total Distance",
        "Inclination",
        "Elevation Gain",
        "Pace",
        "Step Count",
        "Resistance Level",
        "Stride Count",
        "Expended Energy",
        "Heart Rate Measurement",
        "Metabolic Equivalent",
        "Elapsed Time",
        "Remaining Time",
        "Power Measurement",
        "Force on Belt and Power Output",
        "User Data Retention"
    ]

    /// Bit names for the second 32-bit field, which declares settable targets.
    static let targetSettingNames = [
        "Speed Target Setting",
        "Inclination Target Setting",
        "Resistance Target Setting",
        "Power Target Setting",
        "Heart Rate Target Setting",
        "Targeted Expended Energy Configuration",
        "Targeted Step Number Configuration",
        "Targeted Stride Number Configuration",
        "Targeted Distance Configuration",
        "Targeted Training Time Configuration",
        "Targeted Time in Two Heart Rate Zones",
        "Targeted Time in Three Heart Rate Zones",
        "Targeted Time in Five Heart Rate Zones",
        "Indoor Bike Simulation Parameters",
        "Wheel Circumference Configuration",
        "Spin Down Control",
        "Targeted Cadence Configuration"
    ]

    // MARK: - Public Helpers

    /// Decodes a Fitness Machine Feature payload.
    /// - Parameter data: The raw characteristic value, expected to be 8 bytes.
    /// - Returns: One field per declared capability, plus the raw bit fields.
    static func decode(_ data: Data) -> [DecodedField] {
        var reader = ByteReader(data)

        guard let features = reader.uint32() else {
            return [DecodedField(label: "Error", value: "Payload too short for the 4-byte feature field")]
        }

        let supportedFeatures = BitFieldFormatter.setFlags(in: features, names: featureNames)
        var fields: [DecodedField] = [
            DecodedField(
                label: "Machine Features",
                value: supportedFeatures.isEmpty ? "None declared" : supportedFeatures.joined(separator: ", "),
                detail: "0x\(String(format: "%08X", features))"
            )
        ]

        if let targetSettings = reader.uint32() {
            let supportedTargets = BitFieldFormatter.setFlags(in: targetSettings, names: targetSettingNames)
            fields.append(DecodedField(
                label: "Target Setting Features",
                value: supportedTargets.isEmpty ? "None declared" : supportedTargets.joined(separator: ", "),
                detail: "0x\(String(format: "%08X", targetSettings))"
            ))
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
