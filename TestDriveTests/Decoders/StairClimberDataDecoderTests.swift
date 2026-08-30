//
//  StairClimberDataDecoderTests.swift
//  TestDriveTests
//

import Foundation
import Testing
@testable import TestDrive

/// Checks the specification-conforming Stair Climber Data path, and that a
/// non-conforming payload is routed away from it rather than silently mis-parsed.
@Suite("Stair climber data (specification)")
struct StairClimberDataDecoderTests {

    // MARK: - Dispatch

    @Test("A captured vendor packet is routed to the vendor decoder")
    func vendorPacketIsRouted() {
        let fields = StairClimberDataDecoder.decode(CapturedPackets.session1Final)

        // Correct routing is observable through the vendor-only fields and through
        // the values themselves: the specification layout would have produced
        // "Positive Elevation Gain: 96 m" for this packet.
        #expect(fields.value("Layout")?.contains("LiXuan") == true)
        #expect(fields.value("Step Count") == "96 steps")
        #expect(fields.value("Positive Elevation Gain") == "11 m")
    }

    // MARK: - Expected Length

    @Test("Flags with every field present require 25 bytes")
    func expectedLengthForAllFieldsPresent() {
        // This is the arithmetic that exposed the vendor layout: the machine sets
        // these flags but sends only 23 bytes.
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x03FE) == 25)
    }

    @Test("Flags with nothing optional present require only the mandatory fields")
    func expectedLengthForMinimalFlags() {
        // Bit 0 clear means Floors and Step Count are present: 2 flags + 4 bytes.
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0000) == 6)

        // Bit 0 set suppresses both, leaving just the flags.
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0001) == 2)
    }

    @Test("Each optional field contributes its specified width")
    func expectedLengthPerField() {
        let baseline = 6  // flags + floors + step count

        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0002) == baseline + 2)  // step per minute
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0004) == baseline + 2)  // average step rate
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0008) == baseline + 2)  // elevation gain
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0010) == baseline + 2)  // stride count
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0020) == baseline + 5)  // expended energy block
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0040) == baseline + 1)  // heart rate
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0080) == baseline + 1)  // metabolic equivalent
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0100) == baseline + 2)  // elapsed time
        #expect(StairClimberDataDecoder.expectedPayloadLength(forFlags: 0x0200) == baseline + 2)  // remaining time
    }

    // MARK: - Conforming Payloads

    @Test("A conforming payload decodes in specification field order")
    func conformingPayloadDecodes() {
        // Synthesised, not captured: no machine on hand produces a conforming
        // Stair Climber Data payload. Flags 0x0021 select Floors, Step Count and
        // the expended energy block.
        let payload = Data([
            0x20, 0x00,              // flags: bit 0 clear, bit 5 set
            0x07, 0x00,              // floors = 7
            0x96, 0x00,              // step count = 150
            0x2C, 0x00,              // total energy = 44 kcal
            0x84, 0x03,              // energy per hour = 900 kcal/h
            0x0F                     // energy per minute = 15 kcal/min
        ])

        let fields = StairClimberDataDecoder.decode(payload)

        #expect(fields.value("Floors") == "7 floors")
        #expect(fields.value("Step Count") == "150 steps")
        #expect(fields.value("Total Energy") == "44 kcal")
        #expect(fields.value("Energy Per Hour") == "900 kcal/h")
        #expect(fields.value("Energy Per Minute") == "15 kcal/min")
        #expect(!fields.hasField("⚠️ Layout Mismatch"))
        #expect(!fields.hasField("Undecoded Trailing Bytes"))
    }

    @Test("Bit 0 set suppresses floors and step count")
    func moreDataBitSuppressesCumulativeFields() {
        // Synthesised. Bit 0 set, bit 8 set: elapsed time only.
        let payload = Data([0x01, 0x01, 0x3C, 0x00])
        let fields = StairClimberDataDecoder.decode(payload)

        #expect(!fields.hasField("Floors"))
        #expect(!fields.hasField("Step Count"))
        #expect(fields.value("Elapsed Time") == "1:00")
    }

    // MARK: - Mismatch Detection

    @Test("A payload shorter than its flags promise is flagged")
    func shortPayloadIsFlagged() {
        // Synthesised: flags promise floors, step count and elapsed time (8 bytes)
        // but only floors and step count arrive. This is the general form of the bug
        // the vendor layout exhibited, and it must not pass silently.
        let payload = Data([0x00, 0x01, 0x02, 0x00, 0x10, 0x00])
        let fields = StairClimberDataDecoder.decode(payload)

        let warning = fields.value("⚠️ Layout Mismatch")
        #expect(warning != nil)
        #expect(warning?.contains("8") == true)
        #expect(warning?.contains("6") == true)
    }

    @Test("Trailing bytes beyond the flags are surfaced")
    func trailingBytesAreSurfaced() {
        // Synthesised: flags promise only floors and step count, but two extra
        // bytes follow.
        let payload = Data([0x00, 0x00, 0x02, 0x00, 0x10, 0x00, 0xAB, 0xCD])
        let fields = StairClimberDataDecoder.decode(payload)

        #expect(fields.value("Undecoded Trailing Bytes") == "2 byte(s)")
        #expect(fields.detail("Undecoded Trailing Bytes") == "AB CD")
    }

    @Test("A payload too short for the flags field reports an error")
    func truncatedFlagsReportError() {
        #expect(StairClimberDataDecoder.decode(Data([0x00])).value("Error") != nil)
        #expect(StairClimberDataDecoder.decode(Data()).value("Error") != nil)
    }
}
