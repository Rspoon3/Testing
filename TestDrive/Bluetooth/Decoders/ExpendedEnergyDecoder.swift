//
//  ExpendedEnergyDecoder.swift
//  TestDrive
//

import Foundation

/// Decodes the three-part Expended Energy block shared by every Fitness Machine
/// Service data characteristic: total energy, energy per hour, and energy per minute.
enum ExpendedEnergyDecoder {

    // MARK: - Public Helpers

    /// Consumes and decodes the Expended Energy block at the reader's current position.
    /// - Parameter reader: The cursor positioned at the start of the block.
    /// - Returns: Up to three decoded fields. A total of `0xFFFF` or a rate of `0xFF`
    ///   means "data not available" per the specification and is reported as such.
    static func decode(from reader: inout ByteReader) -> [DecodedField] {
        var fields: [DecodedField] = []

        if let totalEnergy = reader.uint16() {
            fields.append(DecodedField(
                label: "Total Energy",
                value: totalEnergy == 0xFFFF ? "Not available" : "\(totalEnergy) kcal"
            ))
        }

        if let energyPerHour = reader.uint16() {
            fields.append(DecodedField(
                label: "Energy Per Hour",
                value: energyPerHour == 0xFFFF ? "Not available" : "\(energyPerHour) kcal/h"
            ))
        }

        if let energyPerMinute = reader.uint8() {
            fields.append(DecodedField(
                label: "Energy Per Minute",
                value: energyPerMinute == 0xFF ? "Not available" : "\(energyPerMinute) kcal/min"
            ))
        }

        return fields
    }
}
