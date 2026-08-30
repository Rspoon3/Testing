//
//  DecodedFieldLookup.swift
//  TestDriveTests
//

import Foundation
@testable import TestDrive

extension [DecodedField] {
    /// The formatted value of the field with the given label.
    /// - Parameter label: The exact field label.
    /// - Returns: The field's value, or `nil` when no field carries that label.
    func value(_ label: String) -> String? {
        first { $0.label == label }?.value
    }

    /// The supporting detail of the field with the given label.
    /// - Parameter label: The exact field label.
    /// - Returns: The field's detail, or `nil`.
    func detail(_ label: String) -> String? {
        first { $0.label == label }?.detail
    }

    /// Whether a field with the given label is present.
    /// - Parameter label: The exact field label.
    /// - Returns: `true` when the label appears.
    func hasField(_ label: String) -> Bool {
        contains { $0.label == label }
    }
}
