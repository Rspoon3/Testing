//
//  GATTDecoderRegistryTests.swift
//  TestDriveTests
//

import CoreBluetooth
import Foundation
import Testing
@testable import TestDrive

/// Checks that values reach the right decoder, and that anything unrecognised is
/// still surfaced rather than dropped.
@Suite("Decoder registry")
struct GATTDecoderRegistryTests {

    @Test("Device information strings decode to text")
    func deviceInformationStrings() {
        let manufacturer = GATTDecoderRegistry.decode(
            CapturedPackets.manufacturerName,
            for: GATTIdentifier.Characteristic.manufacturerName
        )
        let model = GATTDecoderRegistry.decode(
            CapturedPackets.modelNumber,
            for: GATTIdentifier.Characteristic.modelNumber
        )
        let firmware = GATTDecoderRegistry.decode(
            CapturedPackets.firmwareRevision,
            for: GATTIdentifier.Characteristic.firmwareRevision
        )

        #expect(manufacturer.value("Manufacturer Name") == "LiXuan")
        #expect(model.value("Model Number") == "E-masX")
        #expect(firmware.value("Firmware Revision") == "V1.1")
    }

    @Test("Stair climber data reaches the vendor decoder through the registry")
    func stairClimberRouting() {
        let fields = GATTDecoderRegistry.decode(
            CapturedPackets.session1Final,
            for: GATTIdentifier.Characteristic.stairClimberData
        )

        #expect(fields.value("Step Count") == "96 steps")
        #expect(fields.value("Floors") == "4 floors")
    }

    @Test("Each characteristic with a dedicated decoder is routed to it")
    func dedicatedDecoderRouting() {
        let cases: [(CBUUID, Data, String)] = [
            (GATTIdentifier.Characteristic.fitnessMachineFeature, CapturedPackets.fitnessMachineFeature, "Machine Features"),
            (GATTIdentifier.Characteristic.trainingStatus, CapturedPackets.trainingStatusIdle, "Training Status"),
            (GATTIdentifier.Characteristic.fitnessMachineStatus, CapturedPackets.fitnessMachineStatusStarted, "Status"),
            (GATTIdentifier.Characteristic.supportedHeartRateRange, CapturedPackets.supportedHeartRateRange, "Minimum Heart Rate"),
            (GATTIdentifier.Characteristic.batteryLevel, Data([0x5A]), "Battery Level")
        ]

        for (uuid, data, expectedLabel) in cases {
            let fields = GATTDecoderRegistry.decode(data, for: uuid)
            #expect(fields.hasField(expectedLabel), "\(GATTIdentifier.name(for: uuid)) did not produce \(expectedLabel)")
        }
    }

    @Test("An unrecognised characteristic is inspected rather than dropped")
    func unknownCharacteristicIsInspected() {
        // The captured machine exposes a vendor characteristic with no assigned
        // number, so unknown payloads have to stay visible.
        let vendorUUID = CBUUID(string: "8EC90003-F315-4F60-9FB8-838830DAEA50")
        let fields = GATTDecoderRegistry.decode(Data([0x01, 0x02, 0x03, 0x04]), for: vendorUUID)

        #expect(fields.value("Length") == "4 byte(s)")
        #expect(fields.value("Hex") == "01 02 03 04")
        #expect(fields.value("As UInt16 (little-endian)") == "513 1027")
        #expect(fields.value("As UInt16 (big-endian)") == "258 772")
        #expect(fields.value("As UInt32 (little-endian)") == "67305985")
    }

    @Test("An empty unrecognised value is reported, not silently skipped")
    func emptyUnknownValue() {
        let fields = GATTDecoderRegistry.decode(Data(), for: CBUUID(string: "FFF1"))

        #expect(fields.value("Value") == "Empty (0 bytes)")
    }

    @Test("A device information string that is not valid UTF-8 falls back to inspection")
    func invalidUTF8FallsBack() {
        let fields = GATTDecoderRegistry.decode(
            Data([0xFF, 0xFE, 0xFD]),
            for: GATTIdentifier.Characteristic.manufacturerName
        )

        #expect(!fields.hasField("Manufacturer Name"))
        #expect(fields.value("Hex") == "FF FE FD")
    }

    @Test("Dedicated decoder coverage is reported accurately")
    func dedicatedDecoderCoverage() {
        #expect(GATTDecoderRegistry.hasDedicatedDecoder(for: GATTIdentifier.Characteristic.stairClimberData))
        #expect(GATTDecoderRegistry.hasDedicatedDecoder(for: GATTIdentifier.Characteristic.fitnessMachineFeature))
        #expect(!GATTDecoderRegistry.hasDedicatedDecoder(for: GATTIdentifier.Characteristic.fitnessMachineControlPoint))
        #expect(!GATTDecoderRegistry.hasDedicatedDecoder(for: CBUUID(string: "FFF1")))
    }

    @Test("Known identifiers are named and unknown ones are marked")
    func identifierNaming() {
        #expect(GATTIdentifier.name(for: GATTIdentifier.Characteristic.stairClimberData) == "Stair Climber Data")
        #expect(GATTIdentifier.name(for: GATTIdentifier.Service.fitnessMachine) == "Fitness Machine")
        #expect(GATTIdentifier.name(for: GATTIdentifier.Service.nordicSecureDFU) == "Nordic Secure DFU")
        #expect(GATTIdentifier.name(for: CBUUID(string: "FFF1")).contains("Unknown"))
        #expect(!GATTIdentifier.isKnown(CBUUID(string: "FFF1")))
    }
}
