//
//  BitFieldFormatter.swift
//  TestDrive
//

import Foundation

/// Turns specification bit fields into readable lists of set flags.
enum BitFieldFormatter {
    /// Returns the names of every set bit in the given value.
    /// - Parameters:
    ///   - value: The bit field to inspect.
    ///   - names: Bit names indexed from the least significant bit.
    /// - Returns: The names of the set bits, plus `"Bit n"` entries for set bits with no name.
    static func setFlags(in value: UInt32, names: [String]) -> [String] {
        (0..<32).compactMap { bit in
            guard value & (1 << UInt32(bit)) != 0 else { return nil }
            return bit < names.count ? names[bit] : "Bit \(bit) (reserved)"
        }
    }

    /// Returns the names of every set bit in the given 16-bit value.
    /// - Parameters:
    ///   - value: The bit field to inspect.
    ///   - names: Bit names indexed from the least significant bit.
    /// - Returns: The names of the set bits.
    static func setFlags(in value: UInt16, names: [String]) -> [String] {
        setFlags(in: UInt32(value), names: names)
    }

    /// A binary rendering of a 16-bit value, most significant bit first.
    /// - Parameter value: The value to render.
    /// - Returns: A 16-character binary string grouped into bytes, e.g. `"00000001 01000110"`.
    static func binaryDescription(_ value: UInt16) -> String {
        let bits = String(value, radix: 2)
        let padded = String(repeating: "0", count: 16 - bits.count) + bits
        let index = padded.index(padded.startIndex, offsetBy: 8)
        return "\(padded[padded.startIndex..<index]) \(padded[index...])"
    }
}
