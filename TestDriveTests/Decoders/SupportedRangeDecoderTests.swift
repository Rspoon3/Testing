//
//  SupportedRangeDecoderTests.swift
//  TestDriveTests
//

import CoreBluetooth
import Foundation
import Testing
@testable import TestDrive

/// Checks the five supported-range characteristics, including the two the captured
/// machine reports in a way the specification does not anticipate.
@Suite("Supported ranges")
struct SupportedRangeDecoderTests {

    @Test("Reversed heart rate bounds are flagged rather than shown as-is")
    func reversedHeartRateBoundsAreFlagged() {
        // The firmware sends 200 then 50, which reads as a 200 bpm minimum and a
        // 50 bpm maximum unless the reversal is caught.
        let fields = SupportedRangeDecoder.decode(
            CapturedPackets.supportedHeartRateRange,
            uuid: GATTIdentifier.Characteristic.supportedHeartRateRange
        )

        #expect(fields.value("Minimum Heart Rate") == "200 bpm")
        #expect(fields.value("Maximum Heart Rate") == "50 bpm")
        #expect(fields.detail("⚠️ Reversed Bounds") == "Actual range is 50–200 bpm")
    }

    @Test("Correctly ordered heart rate bounds are not flagged")
    func correctHeartRateBoundsAreNotFlagged() {
        // Synthesised: 50–200 in the specified order.
        let fields = SupportedRangeDecoder.decode(
            Data([0x32, 0xC8, 0x01]),
            uuid: GATTIdentifier.Characteristic.supportedHeartRateRange
        )

        #expect(fields.value("Minimum Heart Rate") == "50 bpm")
        #expect(fields.value("Maximum Heart Rate") == "200 bpm")
        #expect(!fields.hasField("⚠️ Reversed Bounds"))
    }

    @Test("Resistance levels are shown as integers, not scaled to a tenth")
    func resistanceLevelsShownAsIntegers() {
        // The machine uses integer levels 1–25, matching its console SPEED buttons.
        // Applying the specification's 0.1 resolution rendered this as "0.1 to 2.5".
        let fields = SupportedRangeDecoder.decode(
            CapturedPackets.supportedResistanceLevelRange,
            uuid: GATTIdentifier.Characteristic.supportedResistanceLevelRange
        )

        #expect(fields.value("Minimum Resistance") == "1")
        #expect(fields.value("Maximum Resistance") == "25")
        #expect(fields.value("Minimum Increment") == "1")
    }

    @Test("The specification's tenth resolution is still reported as detail")
    func resistanceScaledValueKeptAsDetail() {
        let fields = SupportedRangeDecoder.decode(
            CapturedPackets.supportedResistanceLevelRange,
            uuid: GATTIdentifier.Characteristic.supportedResistanceLevelRange
        )

        #expect(fields.detail("Maximum Resistance")?.contains("2.5") == true)
    }

    @Test("Speed range uses hundredths of a km/h")
    func speedRangeScaling() {
        let fields = SupportedRangeDecoder.decode(
            CapturedPackets.supportedSpeedRange,
            uuid: GATTIdentifier.Characteristic.supportedSpeedRange
        )

        #expect(fields.value("Minimum") == "0.00 km/h")
        #expect(fields.value("Maximum") == "0.00 km/h")
        #expect(fields.value("Minimum Increment") == "0.01 km/h")
    }

    @Test("Inclination range is signed and scaled to a tenth of a percent")
    func inclinationRangeIsSigned() {
        // Synthesised: -10.0% to 15.0% in 0.5% steps.
        let fields = SupportedRangeDecoder.decode(
            Data([0x9C, 0xFF, 0x96, 0x00, 0x05, 0x00]),
            uuid: GATTIdentifier.Characteristic.supportedInclinationRange
        )

        #expect(fields.value("Minimum") == "-10.0 %")
        #expect(fields.value("Maximum") == "15.0 %")
        #expect(fields.value("Minimum Increment") == "0.5 %")
    }

    @Test("Power range is reported in whole watts")
    func powerRangeInWatts() {
        // Synthesised: 0–1000 W in 1 W steps.
        let fields = SupportedRangeDecoder.decode(
            Data([0x00, 0x00, 0xE8, 0x03, 0x01, 0x00]),
            uuid: GATTIdentifier.Characteristic.supportedPowerRange
        )

        #expect(fields.value("Minimum") == "0 W")
        #expect(fields.value("Maximum") == "1000 W")
        #expect(fields.value("Minimum Increment") == "1 W")
    }

    @Test("A truncated range payload reports an error")
    func truncatedPayloadReportsError() {
        for uuid in [
            GATTIdentifier.Characteristic.supportedSpeedRange,
            GATTIdentifier.Characteristic.supportedHeartRateRange,
            GATTIdentifier.Characteristic.supportedResistanceLevelRange
        ] {
            #expect(SupportedRangeDecoder.decode(Data([0x01]), uuid: uuid).value("Error") != nil)
        }
    }

    @Test("A UUID that is not a supported range reports an error")
    func wrongUUIDReportsError() {
        let fields = SupportedRangeDecoder.decode(
            CapturedPackets.supportedSpeedRange,
            uuid: GATTIdentifier.Characteristic.batteryLevel
        )

        #expect(fields.value("Error") != nil)
    }
}
