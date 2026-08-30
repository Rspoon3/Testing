//
//  RawValueInspector.swift
//  TestDrive
//

import Foundation

/// Renders an undocumented payload every plausible way at once.
///
/// STEPR does not publish its Bluetooth protocol, so a machine is likely to expose
/// vendor-specific characteristics with no assigned number. Rather than showing
/// only a hex dump, this offers the interpretations that actually help identify a
/// field: UTF-8 text, byte-by-byte values, and 16- and 32-bit words in both
/// endiannesses.
enum RawValueInspector {

    // MARK: - Public Helpers

    /// Produces every plausible interpretation of an unrecognised payload.
    /// - Parameter data: The raw characteristic value.
    /// - Returns: A set of fields describing the payload's size and candidate decodes.
    static func inspect(_ data: Data) -> [DecodedField] {
        guard !data.isEmpty else {
            return [DecodedField(label: "Value", value: "Empty (0 bytes)")]
        }

        var fields: [DecodedField] = [
            DecodedField(label: "Length", value: "\(data.count) byte(s)"),
            DecodedField(label: "Hex", value: data.hexDescription)
        ]

        if let text = String(data: data, encoding: .utf8), text.allSatisfy({ !$0.isNewline }), !text.isEmpty {
            fields.append(DecodedField(label: "As UTF-8", value: text))
        }

        fields.append(DecodedField(label: "As ASCII", value: data.printableASCIIDescription))

        let bytes = [UInt8](data)
        fields.append(DecodedField(
            label: "As UInt8 Values",
            value: bytes.map(String.init).joined(separator: " ")
        ))

        if data.count >= 2 {
            fields.append(DecodedField(
                label: "As UInt16 (little-endian)",
                value: words(bytes, size: 2, littleEndian: true)
            ))
            fields.append(DecodedField(
                label: "As UInt16 (big-endian)",
                value: words(bytes, size: 2, littleEndian: false)
            ))
        }

        if data.count >= 4 {
            fields.append(DecodedField(
                label: "As UInt32 (little-endian)",
                value: words(bytes, size: 4, littleEndian: true)
            ))
        }

        return fields
    }

    // MARK: - Private Helpers

    /// Groups bytes into fixed-width words and formats them as decimal values.
    private static func words(_ bytes: [UInt8], size: Int, littleEndian: Bool) -> String {
        stride(from: 0, to: bytes.count - size + 1, by: size).map { index in
            let chunk = bytes[index..<(index + size)]
            let ordered = littleEndian ? Array(chunk.reversed()) : Array(chunk)
            let value = ordered.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            return String(value)
        }
        .joined(separator: " ")
    }
}
