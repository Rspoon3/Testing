//
//  ByteReader.swift
//  TestDrive
//

import Foundation

/// A forward-only cursor over a `Data` buffer that reads the little-endian integer
/// types used throughout the Bluetooth GATT specifications.
///
/// Every read is bounds-checked and returns `nil` rather than trapping, because
/// real fitness equipment regularly truncates or pads its packets in ways the
/// specification does not describe.
struct ByteReader {
    private let data: Data
    private var offset: Int

    /// The number of bytes that have not been consumed yet.
    var remainingByteCount: Int { max(0, data.count - offset) }

    /// The bytes that have not been consumed yet.
    var remainingBytes: Data {
        guard remainingByteCount > 0 else { return Data() }
        return data.subdata(in: offset..<data.count)
    }

    // MARK: - Initializer

    /// Creates a reader positioned at the start of the given buffer.
    /// - Parameter data: The raw characteristic value to read from.
    init(_ data: Data) {
        self.data = Data(data)
        self.offset = 0
    }

    // MARK: - Public Helpers

    /// Reads an unsigned 8-bit integer.
    mutating func uint8() -> UInt8? {
        guard let bytes = take(1) else { return nil }
        return bytes[0]
    }

    /// Reads a signed 8-bit integer.
    mutating func int8() -> Int8? {
        guard let value = uint8() else { return nil }
        return Int8(bitPattern: value)
    }

    /// Reads a little-endian unsigned 16-bit integer.
    mutating func uint16() -> UInt16? {
        guard let bytes = take(2) else { return nil }
        return UInt16(bytes[0]) | UInt16(bytes[1]) << 8
    }

    /// Reads a little-endian signed 16-bit integer.
    mutating func int16() -> Int16? {
        guard let value = uint16() else { return nil }
        return Int16(bitPattern: value)
    }

    /// Reads a little-endian unsigned 24-bit integer, the `uint24` type used for
    /// distance fields in the Fitness Machine Service.
    mutating func uint24() -> UInt32? {
        guard let bytes = take(3) else { return nil }
        return UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16
    }

    /// Reads a little-endian unsigned 32-bit integer.
    mutating func uint32() -> UInt32? {
        guard let bytes = take(4) else { return nil }
        return UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
    }

    /// Reads a little-endian signed 32-bit integer.
    mutating func int32() -> Int32? {
        guard let value = uint32() else { return nil }
        return Int32(bitPattern: value)
    }

    /// Consumes the rest of the buffer as a UTF-8 string.
    mutating func utf8String() -> String? {
        let bytes = remainingBytes
        offset = data.count
        guard !bytes.isEmpty else { return nil }
        return String(data: bytes, encoding: .utf8)
    }

    // MARK: - Private Helpers

    /// Consumes and returns `count` bytes, or `nil` when the buffer is exhausted.
    private mutating func take(_ count: Int) -> [UInt8]? {
        guard remainingByteCount >= count else { return nil }
        let slice = Array(data[(data.startIndex + offset)..<(data.startIndex + offset + count)])
        offset += count
        return slice
    }
}
