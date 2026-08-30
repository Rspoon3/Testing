//
//  LiXuanStairClimberDataDecoderTests.swift
//  TestDriveTests
//

import Foundation
import Testing
@testable import TestDrive

/// Checks the vendor Stair Climber Data layout against packets captured from a real
/// machine, with the expected values taken from photographs of its console.
@Suite("LiXuan stair climber data")
struct LiXuanStairClimberDataDecoderTests {

    // MARK: - Layout Recognition

    @Test("Recognises the vendor layout")
    func matchesVendorLayout() {
        #expect(LiXuanStairClimberDataDecoder.matches(CapturedPackets.session1Final, flags: 0x03FE))
    }

    @Test("Rejects a payload of the specification length")
    func rejectsConformingLength() {
        // A 25-byte payload is what the flags actually promise, so it must go to the
        // specification decoder rather than this one.
        let conforming = Data(repeating: 0, count: 25)
        #expect(!LiXuanStairClimberDataDecoder.matches(conforming, flags: 0x03FE))
    }

    @Test("Rejects the right length with different flags")
    func rejectsDifferentFlags() {
        #expect(!LiXuanStairClimberDataDecoder.matches(CapturedPackets.session1Final, flags: 0x0002))
    }

    @Test("Parsing returns nil for a payload that is not this layout")
    func parseRejectsOtherPayloads() {
        #expect(LiXuanStairClimberDataDecoder.parse(Data([0x02, 0x00, 0x10, 0x00])) == nil)
        #expect(LiXuanStairClimberDataDecoder.parse(Data()) == nil)
    }

    // MARK: - Console-Verified Values

    @Test("Session 1 final packet matches the console")
    func session1FinalMatchesConsole() throws {
        let sample = try #require(LiXuanStairClimberDataDecoder.parse(CapturedPackets.session1Final))

        #expect(sample.stepCount == 96)                  // console STEPS 96
        #expect(sample.floors == 4)                      // console FLOORS 4
        #expect(sample.totalEnergyKilocalories == 16)    // console CALORIES 16
        #expect(sample.elapsedSeconds == 88)             // console TIME 1:28
        #expect(sample.elevationGainMetres == 11)        // console ALTITUDE 38 ft
        #expect(sample.speedLevel == 0)                  // console SPEED 0
        #expect(sample.heartRate == 0)                   // console PULSE 0
        #expect(sample.remainingSeconds == 0)
        #expect(sample.metabolicEquivalentRaw == 0)
    }

    @Test("Session 3 final packet matches the console")
    func session3FinalMatchesConsole() throws {
        let sample = try #require(LiXuanStairClimberDataDecoder.parse(CapturedPackets.session3Final))

        #expect(sample.stepCount == 126)
        #expect(sample.floors == 6)
        #expect(sample.totalEnergyKilocalories == 21)
        #expect(sample.elapsedSeconds == 130)
        #expect(sample.elevationGainMetres == 15)
    }

    @Test("Speed level is read from the Step Per Minute slot, not a step rate")
    func speedLevelComesFromStepPerMinuteSlot() throws {
        // The highest speed reached in session 1 was 16. Decoding this slot as
        // "Step Count" was the original mislabelling.
        let sample = try #require(LiXuanStairClimberDataDecoder.parse(CapturedPackets.session1AtPeakSpeed))

        #expect(sample.speedLevel == 16)
        #expect(sample.stepCount == 63)
        #expect(sample.elevationGainMetres == 7)
        #expect(sample.elapsedSeconds == 65)
    }

    // MARK: - Floor Derivation

    @Test("Floors are derived from the byte 2 countdown")
    func floorsDerivedFromCountdown() throws {
        // Byte 2 starts at 253 and decrements once per floor.
        let base = try #require(LiXuanStairClimberDataDecoder.parse(CapturedPackets.session3AfterReset))
        #expect(base.floors == 0)
        #expect(base.floorsSlotRaw == 0x10FD)

        let twoFloors = try #require(LiXuanStairClimberDataDecoder.parse(CapturedPackets.session3CarriedOver))
        #expect(twoFloors.floors == 2)
        #expect(twoFloors.floorsSlotRaw == 0x10FB)

        let sixFloors = try #require(LiXuanStairClimberDataDecoder.parse(CapturedPackets.session3Final))
        #expect(sixFloors.floors == 6)
        #expect(sixFloors.floorsSlotRaw == 0x10F7)
    }

    @Test("The idle all-zero packet reports no floors rather than an error")
    func idlePacketReportsZeroFloors() throws {
        let sample = try #require(LiXuanStairClimberDataDecoder.parse(CapturedPackets.idle))

        #expect(sample.floorsSlotRaw == 0)
        #expect(sample.floors == 0)
        #expect(sample.stepCount == 0)
        #expect(sample.elapsedSeconds == 0)
    }

    @Test("An unrecognised floor encoding reports nil rather than a wrong count")
    func unrecognisedFloorEncodingReturnsNil() {
        // High byte other than 0x10 means the countdown relationship does not hold.
        var bytes = [UInt8](CapturedPackets.session1Final)
        bytes[3] = 0x20
        let sample = LiXuanStairClimberDataDecoder.parse(Data(bytes))

        #expect(sample?.floors == nil)
    }

    // MARK: - Field Output

    @Test("Total energy reported as unavailable decodes to nil")
    func unavailableEnergyDecodesToNil() throws {
        var bytes = [UInt8](CapturedPackets.session1Final)
        bytes[12] = 0xFF
        bytes[13] = 0xFF
        let sample = try #require(LiXuanStairClimberDataDecoder.parse(Data(bytes)))

        #expect(sample.totalEnergyKilocalories == nil)
    }

    @Test("Decoded fields carry the console-verified values")
    func decodedFieldsCarryConsoleValues() {
        let fields = LiXuanStairClimberDataDecoder.decode(CapturedPackets.session1Final)

        #expect(fields.value("Step Count") == "96 steps")
        #expect(fields.value("Floors") == "4 floors")
        #expect(fields.value("Total Energy") == "16 kcal")
        #expect(fields.value("Elapsed Time") == "1:28")
        #expect(fields.value("Positive Elevation Gain") == "11 m")
        #expect(fields.value("Current Speed") == "0")
        #expect(fields.value("Heart Rate") == "0 bpm")
    }

    @Test("Stride count is reported as absent, not as zero")
    func strideCountReportedAbsent() {
        // Flag bit 4 claims stride count is present but the firmware omits it.
        // Reporting "0 strides" would be a fabricated value.
        let fields = LiXuanStairClimberDataDecoder.decode(CapturedPackets.session1Final)

        #expect(fields.value("Stride Count") == "Not transmitted")
    }

    @Test("The non-standard layout is called out")
    func layoutIsFlagged() {
        let fields = LiXuanStairClimberDataDecoder.decode(CapturedPackets.session1Final)

        #expect(fields.value("Layout")?.contains("non-standard") == true)
    }

    @Test("Energy per hour and per minute are reported unavailable")
    func energyRatesUnavailable() {
        let fields = LiXuanStairClimberDataDecoder.decode(CapturedPackets.session1Final)

        #expect(fields.value("Energy Per Hour") == "Not available")
        #expect(fields.value("Energy Per Minute") == "Not available")
    }

    @Test("No trailing bytes are left undecoded")
    func noUndecodedTrailingBytes() {
        let fields = LiXuanStairClimberDataDecoder.decode(CapturedPackets.session1Final)

        #expect(!fields.hasField("Undecoded Trailing Bytes"))
    }
}
