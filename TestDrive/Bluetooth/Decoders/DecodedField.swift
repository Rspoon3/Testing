//
//  DecodedField.swift
//  TestDrive
//

import Foundation

/// A single named value pulled out of a raw GATT characteristic payload.
struct DecodedField: Identifiable, Hashable, Sendable {
    /// The field name, taken from the Bluetooth specification where one applies.
    let label: String

    /// The formatted value, including its unit.
    let value: String

    /// Optional supporting text, such as the raw bytes the value was parsed from.
    let detail: String?

    /// Field labels are unique within a single decode, so the label doubles as the identity.
    var id: String { label }

    // MARK: - Initializer

    /// Creates a decoded field.
    /// - Parameters:
    ///   - label: The field name.
    ///   - value: The formatted value, including any unit.
    ///   - detail: Optional supporting text such as the raw bytes.
    init(label: String, value: String, detail: String? = nil) {
        self.label = label
        self.value = value
        self.detail = detail
    }

    // MARK: - Public Helpers

    /// Creates a field describing a numeric value with a unit suffix.
    /// - Parameters:
    ///   - label: The field name.
    ///   - value: The numeric value.
    ///   - unit: The unit to append, or `nil` for a unitless quantity.
    /// - Returns: A formatted field.
    static func measurement(_ label: String, _ value: some Numeric & CustomStringConvertible, unit: String? = nil) -> DecodedField {
        guard let unit else {
            return DecodedField(label: label, value: value.description)
        }
        return DecodedField(label: label, value: "\(value) \(unit)")
    }

    /// Creates a field describing a duration expressed in whole seconds.
    /// - Parameters:
    ///   - label: The field name.
    ///   - seconds: The duration in seconds.
    /// - Returns: A field formatted as `h:mm:ss` (or `m:ss` under an hour).
    static func duration(_ label: String, seconds: Int) -> DecodedField {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        let formatted = hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
            : String(format: "%d:%02d", minutes, remainingSeconds)
        return DecodedField(label: label, value: formatted, detail: "\(seconds) s")
    }
}
