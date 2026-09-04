//
//  PitPatTreadmillDataDecoderTests.swift
//  TestDriveTests
//

import CoreBluetooth
import Foundation
import Testing
@testable import TestDrive

/// Checks the PitPat vendor decoder.
///
/// Unlike the stair-climber suites, these payloads are **synthesised** from the
/// reverse-engineered frame layout rather than captured off a machine — the
/// SupeRun `BA10-B` has not been logged yet. They therefore prove the decoder
/// matches the documented layout, not that the layout matches the hardware. Once a
/// real session is logged, the captured frames belong in `CapturedPackets` and the
/// console readings should be asserted against them here.
@Suite("PitPat treadmill decoder")
struct PitPatTreadmillDataDecoderTests {

    // MARK: - Private Helpers

    /// Builds a 31-byte state frame with each documented field at its offset.
    ///
    /// Every parameter is expressed exactly as it appears on the wire, so a test
    /// reads as the byte layout rather than as decoded units.
    private static func stateFrame(
        currentSpeed: UInt16 = 0,
        targetSpeed: UInt16 = 0,
        distanceMetres: UInt32 = 0,
        steps: UInt32 = 0,
        calories: UInt16 = 0,
        durationMilliseconds: UInt32 = 0,
        firmwareVersion: UInt8 = 0,
        flags: UInt8 = 0,
        maximumSpeed: UInt16 = 0
    ) -> Data {
        var bytes = [UInt8](repeating: 0, count: 31)

        bytes[0] = 0x6A                                     // start marker
        bytes[1] = 0x1F                                     // length
        bytes.replaceSubrange(3..<5, with: currentSpeed.bigEndianBytes)
        bytes.replaceSubrange(5..<7, with: targetSpeed.bigEndianBytes)
        bytes.replaceSubrange(7..<11, with: distanceMetres.bigEndianBytes)
        bytes.replaceSubrange(14..<18, with: steps.bigEndianBytes)
        bytes.replaceSubrange(18..<20, with: calories.bigEndianBytes)
        bytes.replaceSubrange(20..<24, with: durationMilliseconds.bigEndianBytes)
        bytes[25] = firmwareVersion
        bytes[26] = flags
        bytes.replaceSubrange(27..<29, with: maximumSpeed.bigEndianBytes)
        bytes[30] = 0x43                                    // end marker

        return Data(bytes)
    }

    /// A frame standing in for a mid-walk notification: 3.20 km/h toward a 4.00 km/h
    /// target, 1.234 km covered, 2048 steps, 87 kcal, 12:30 elapsed, imperial panel.
    private static var midWalkFrame: Data {
        stateFrame(
            currentSpeed: 3200,
            targetSpeed: 4000,
            distanceMetres: 1234,
            steps: 2048,
            calories: 87,
            durationMilliseconds: 750_000,
            firmwareVersion: 10,
            flags: 0x88,
            maximumSpeed: 6000
        )
    }

    // MARK: - Tests

    @Test("Reads every field from its documented offset")
    func readsAllFields() throws {
        let sample = try #require(PitPatTreadmillDataDecoder.parse(Self.midWalkFrame))

        #expect(sample.status == .running)
        #expect(sample.speedKilometresPerHour == 3.2)
        #expect(sample.targetSpeedKilometresPerHour == 4.0)
        #expect(sample.maximumSpeedKilometresPerHour == 6.0)
        #expect(sample.distanceKilometres == 1.234)
        #expect(sample.steps == 2048)
        #expect(sample.calories == 87)
        #expect(sample.elapsedSeconds == 750)
        #expect(sample.firmwareVersion == 10)
        #expect(sample.isImperialPanel)
    }

    @Test("Treats the payload as big-endian, not little-endian like FTMS")
    func readsBigEndian() throws {
        // 0x0C80 is 3200 read big-endian and 32780 read little-endian, so a decoder
        // that reused the FTMS byte order would report 32.78 km/h here.
        let sample = try #require(PitPatTreadmillDataDecoder.parse(Self.stateFrame(currentSpeed: 3200)))
        #expect(sample.speedKilometresPerHour == 3.2)
    }

    @Test("Converts the metric wire values to the units the console shows")
    func convertsToImperial() throws {
        let sample = try #require(PitPatTreadmillDataDecoder.parse(Self.midWalkFrame))

        #expect(abs(sample.speedMilesPerHour - 1.9884) < 0.001)
        #expect(abs(sample.distanceMiles - 0.76678) < 0.001)
    }

    @Test("Decodes the belt state from the status flag bits", arguments: [
        (UInt8(0x18), PitPatTreadmillSample.Status.countdown),
        (UInt8(0x08), PitPatTreadmillSample.Status.running),
        (UInt8(0x10), PitPatTreadmillSample.Status.paused),
        (UInt8(0x00), PitPatTreadmillSample.Status.stopped)
    ])
    func decodesStatus(flags: UInt8, expected: PitPatTreadmillSample.Status) throws {
        let sample = try #require(PitPatTreadmillDataDecoder.parse(Self.stateFrame(flags: flags)))
        #expect(sample.status == expected)
    }

    @Test("Reads the imperial panel bit independently of the belt state")
    func separatesImperialBitFromState() throws {
        let metric = try #require(PitPatTreadmillDataDecoder.parse(Self.stateFrame(flags: 0x08)))
        #expect(metric.status == .running)
        #expect(!metric.isImperialPanel)

        let imperial = try #require(PitPatTreadmillDataDecoder.parse(Self.stateFrame(flags: 0x88)))
        #expect(imperial.status == .running)
        #expect(imperial.isImperialPanel)
    }

    @Test("Rejects a payload shorter than a full state frame")
    func rejectsShortPayloads() {
        #expect(PitPatTreadmillDataDecoder.parse(Data()) == nil)
        #expect(PitPatTreadmillDataDecoder.parse(Data(repeating: 0, count: 30)) == nil)
        #expect(PitPatTreadmillDataDecoder.matches(Data(repeating: 0, count: 31)))
    }

    @Test("Accepts a frame longer than the minimum without shifting any field")
    func acceptsLongerFrames() throws {
        let padded = Self.midWalkFrame + Data([0x00, 0x00, 0x00, 0x00])
        let sample = try #require(PitPatTreadmillDataDecoder.parse(padded))

        #expect(sample.steps == 2048)
        #expect(sample.elapsedSeconds == 750)
        #expect(sample.maximumSpeedKilometresPerHour == 6.0)
    }

    @Test("Reports a short payload as an error field instead of guessing")
    func reportsShortPayloadAsError() {
        let fields = PitPatTreadmillDataDecoder.decode(Data([0x6A, 0x1F, 0x00]))

        #expect(fields.value("Error")?.contains("3 bytes") == true)
        #expect(!fields.hasField("Current Speed"))
    }

    @Test("Formats the fields shown on the characteristic screen")
    func formatsDisplayFields() {
        let fields = PitPatTreadmillDataDecoder.decode(Self.midWalkFrame)

        #expect(fields.value("Layout") == "PitPat treadmill (vendor protocol)")
        #expect(fields.value("Status") == "Running")
        #expect(fields.value("Current Speed") == "3.20 km/h")
        #expect(fields.detail("Current Speed") == "1.99 mph")
        #expect(fields.value("Target Speed") == "4.00 km/h")
        #expect(fields.value("Maximum Speed") == "6.00 km/h")
        #expect(fields.value("Total Distance") == "1.234 km")
        #expect(fields.value("Step Count") == "2048 steps")
        #expect(fields.value("Total Energy") == "87 kcal")
        #expect(fields.value("Elapsed Time") == "12:30")
        #expect(fields.value("Firmware Version") == "10")
        #expect(fields.value("Console Units") == "Imperial (mph/miles)")
    }

    @Test("Surfaces the bytes with no known meaning so a future capture can pin them down")
    func surfacesUndecodedBytes() {
        let frame = Self.stateFrame(flags: 0x08)
        let fields = PitPatTreadmillDataDecoder.decode(frame)

        let undecoded = fields.value("Undecoded Bytes")
        #expect(undecoded?.contains("[0–2] 6A 1F 00") == true)
        #expect(undecoded?.contains("[11–13] 00 00 00") == true)
        #expect(undecoded?.contains("[24] 00") == true)
        #expect(undecoded?.contains("[29–30] 00 43") == true)
    }

    @Test("Routes the PitPat state characteristic to this decoder")
    func registryRoutesStateCharacteristic() {
        let uuid = GATTIdentifier.Characteristic.pitPatState
        #expect(GATTDecoderRegistry.hasDedicatedDecoder(for: uuid))

        let fields = GATTDecoderRegistry.decode(Self.midWalkFrame, for: uuid)
        #expect(fields.value("Layout") == "PitPat treadmill (vendor protocol)")
        #expect(fields.value("Step Count") == "2048 steps")
    }

    @Test("Names the vendor service and characteristics instead of showing raw UUIDs")
    func namesVendorIdentifiers() {
        #expect(GATTIdentifier.name(for: GATTIdentifier.Service.pitPatTreadmill) == "PitPat Treadmill (vendor)")
        #expect(GATTIdentifier.name(for: GATTIdentifier.Characteristic.pitPatCommand) == "PitPat Command")
        #expect(GATTIdentifier.name(for: GATTIdentifier.Characteristic.pitPatState) == "PitPat Treadmill State")
    }
}

// MARK: - Private Helpers

private extension UInt16 {
    /// The value as big-endian bytes, matching the PitPat wire order.
    var bigEndianBytes: [UInt8] { [UInt8(self >> 8), UInt8(self & 0xFF)] }
}

private extension UInt32 {
    /// The value as big-endian bytes, matching the PitPat wire order.
    var bigEndianBytes: [UInt8] {
        [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}
