//
//  ByteReaderTests.swift
//  TestDriveTests
//

import Foundation
import Testing
@testable import TestDrive

/// Checks the little-endian cursor every decoder is built on.
///
/// Bounds safety matters more here than anywhere else: fitness equipment truncates
/// and pads packets in ways the specification does not describe, so a read past the
/// end has to return `nil` rather than trap.
@Suite("Byte reader")
struct ByteReaderTests {

    @Test("Reads little-endian integers in packet order")
    func readsLittleEndianIntegers() {
        var reader = ByteReader(Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]))

        #expect(reader.uint8() == 0x01)
        #expect(reader.uint16() == 0x0302)
        #expect(reader.uint24() == 0x060504)
        #expect(reader.uint8() == 0x07)
        #expect(reader.remainingByteCount == 0)
    }

    @Test("Reads the 16-bit fields used throughout FTMS")
    func readsUInt16Fields() {
        // 0x0060 = 96, the step count from the captured session 1 final packet.
        var reader = ByteReader(Data([0x60, 0x00]))
        #expect(reader.uint16() == 96)
    }

    @Test("Reads signed values as two's complement")
    func readsSignedValues() {
        var reader = ByteReader(Data([0xFF, 0x9C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))

        #expect(reader.int8() == -1)
        #expect(reader.int16() == -100)
        #expect(reader.int32() == -1)
    }

    @Test("Reads 32-bit feature bit fields")
    func readsUInt32() {
        // The captured Fitness Machine Feature payload.
        var reader = ByteReader(Data([0x50, 0x3F, 0x00, 0x00]))
        #expect(reader.uint32() == 0x00003F50)
    }

    @Test("Returns nil rather than trapping when the buffer is exhausted")
    func returnsNilPastTheEnd() {
        var reader = ByteReader(Data([0x01]))

        #expect(reader.uint16() == nil)   // not enough bytes
        #expect(reader.uint8() == 0x01)   // the failed read consumed nothing
        #expect(reader.uint8() == nil)
        #expect(reader.uint24() == nil)
        #expect(reader.uint32() == nil)
    }

    @Test("A failed read leaves the cursor untouched")
    func failedReadDoesNotAdvance() {
        var reader = ByteReader(Data([0xAA, 0xBB, 0xCC]))

        #expect(reader.uint32() == nil)
        #expect(reader.remainingByteCount == 3)
        #expect(reader.uint24() == 0xCCBBAA)
    }

    @Test("An empty buffer yields nothing")
    func emptyBuffer() {
        var reader = ByteReader(Data())

        #expect(reader.uint8() == nil)
        #expect(reader.remainingByteCount == 0)
        #expect(reader.remainingBytes.isEmpty)
        #expect(reader.utf8String() == nil)
    }

    @Test("Remaining bytes reflect what has been consumed")
    func remainingBytesTracksConsumption() {
        var reader = ByteReader(Data([0x01, 0x02, 0x03, 0x04]))

        #expect(reader.remainingByteCount == 4)
        _ = reader.uint16()
        #expect(reader.remainingByteCount == 2)
        #expect(reader.remainingBytes == Data([0x03, 0x04]))
    }

    @Test("Consumes the tail as UTF-8")
    func readsUTF8Tail() {
        // The captured Manufacturer Name payload.
        var reader = ByteReader(CapturedPackets.manufacturerName)

        #expect(reader.utf8String() == "LiXuan")
        #expect(reader.remainingByteCount == 0)
    }

    @Test("Reads a UTF-8 tail after a header")
    func readsUTF8AfterHeader() {
        var reader = ByteReader(Data([0x01, 0x0D]) + Data("Quick Start".utf8))

        #expect(reader.uint8() == 0x01)
        #expect(reader.uint8() == 0x0D)
        #expect(reader.utf8String() == "Quick Start")
    }

    @Test("Works on a slice whose indices do not start at zero")
    func handlesNonZeroBasedSlice() {
        // Data handed over by Core Bluetooth is not always zero-indexed, and reading
        // it with absolute offsets would silently return the wrong bytes.
        let slice = Data([0xFF, 0xFF, 0x60, 0x00]).dropFirst(2)
        var reader = ByteReader(slice)

        #expect(reader.uint16() == 96)
    }
}
