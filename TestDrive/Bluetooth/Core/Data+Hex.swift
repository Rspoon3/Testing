//
//  Data+Hex.swift
//  TestDrive
//

import Foundation

extension Data {
    /// A space-separated, uppercase hex representation of the bytes, e.g. `"0F 1A 2B"`.
    nonisolated var hexDescription: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    /// A compact uppercase hex representation of the bytes with no separators, e.g. `"0F1A2B"`.
    nonisolated var compactHexDescription: String {
        map { String(format: "%02X", $0) }.joined()
    }

    /// The bytes rendered as printable ASCII, substituting `.` for any non-printable byte.
    ///
    /// Useful when probing an undocumented characteristic that may actually be carrying text.
    nonisolated var printableASCIIDescription: String {
        String(map { byte in
            (0x20...0x7E).contains(byte) ? Character(UnicodeScalar(byte)) : "."
        })
    }
}
