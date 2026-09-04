//
//  FitShowTreadmillDataDecoderTests.swift
//  TestDriveTests
//

import CoreBluetooth
import Foundation
import Testing
@testable import TestDrive

/// Checks the FitShow frame layer and vendor decoder.
///
/// As with the PitPat suite, these payloads are **synthesised** from the frame
/// layout in the `qdomyos-zwift` FitShow driver rather than captured off a machine
/// — the maksone `SL-Z01` has not been logged yet. They prove the decoder matches
/// the documented protocol, not that the protocol matches the hardware.
///
/// The framing tests matter most: `FFF1` and `FFE4` are generic vendor UUIDs, so
/// the header/footer/checksum envelope is the only thing separating a real FitShow
/// machine from an unrelated gadget that happens to share a UUID.
@Suite("FitShow treadmill decoder")
struct FitShowTreadmillDataDecoderTests {

    // MARK: - Private Helpers

    /// Wraps a command, parameter, and payload in the FitShow envelope, computing
    /// the XOR checksum the way the machine does.
    private static func frame(command: UInt8, parameter: UInt8, payload: [UInt8] = []) -> Data {
        let body = [command, parameter] + payload
        let checksum = body.reduce(UInt8(0)) { $0 ^ $1 }
        return Data([FitShowFrame.header] + body + [checksum, FitShowFrame.footer])
    }

    /// A running-telemetry frame: 3.2 units/h, incline 2, 12:30 elapsed,
    /// 1.5 units covered, 87 kcal, 2048 steps, 132 bpm.
    private static var runningFrame: Data {
        frame(command: 0x51, parameter: 3, payload: [
            32,             // speed, tenths
            2,              // incline
            0xEE, 0x02,     // elapsed 750 s, little-endian
            0x0F, 0x00,     // distance 1.5, tenths
            0x57, 0x00,     // 87 kcal
            0x00, 0x08,     // 2048 steps
            132             // heart rate
        ])
    }

    // MARK: - Framing Tests

    @Test("Accepts a well-formed envelope and verifies its checksum")
    func parsesEnvelope() throws {
        let parsed = try #require(FitShowFrame(Self.runningFrame))

        #expect(parsed.command == 0x51)
        #expect(parsed.parameter == 3)
        #expect(parsed.family == .status)
        #expect(parsed.isChecksumValid)
        #expect(parsed.payload.count == 11)
    }

    @Test("Rejects a payload that is not FitShow-framed at all")
    func rejectsForeignPayloads() {
        #expect(FitShowFrame(Data()) == nil)
        #expect(FitShowFrame(Data([0x02, 0x51, 0x03])) == nil)          // too short
        #expect(FitShowFrame(Data([0x00, 0x51, 0x00, 0x03])) == nil)    // wrong header
        #expect(FitShowFrame(Data([0x02, 0x51, 0x00, 0x00])) == nil)    // wrong footer
    }

    @Test("Reports a corrupt checksum instead of discarding the frame")
    func reportsChecksumMismatch() throws {
        var bytes = [UInt8](Self.runningFrame)
        bytes[bytes.count - 2] ^= 0xFF

        let parsed = try #require(FitShowFrame(Data(bytes)))
        #expect(!parsed.isChecksumValid)

        // Still surfaced, but flagged, and with no decoded telemetry behind it.
        let fields = try #require(FitShowTreadmillDataDecoder.decode(Data(bytes)))
        #expect(fields.value("Frame") == "Checksum mismatch")
        #expect(!fields.hasField("Current Speed"))
        #expect(FitShowTreadmillDataDecoder.parse(Data(bytes)) == nil)
    }

    @Test("Computes the checksum over the command, parameter, and payload only")
    func checksumCoversTheRightBytes() throws {
        // Header and footer are excluded, so 0x51 ^ 0x03 is the whole checksum for
        // an empty payload.
        let empty = Self.frame(command: 0x51, parameter: 0x03)
        let parsed = try #require(FitShowFrame(empty))

        #expect(parsed.transmittedChecksum == 0x51 ^ 0x03)
        #expect(parsed.isChecksumValid)
    }

    // MARK: - Telemetry Tests

    @Test("Reads every telemetry field from its documented offset")
    func readsTelemetry() throws {
        let sample = try #require(FitShowTreadmillDataDecoder.parse(Self.runningFrame))

        #expect(sample.status == .running)
        #expect(sample.speedTenths == 32)
        #expect(sample.speed == 3.2)
        #expect(sample.incline == 2)
        #expect(sample.elapsedSeconds == 750)
        #expect(sample.distance == 1.5)
        #expect(sample.calories == 87)
        #expect(sample.steps == 2048)
        #expect(sample.heartRate == 132)
        #expect(sample.hasHeartRate)
    }

    @Test("Treats the payload as little-endian, unlike the big-endian PitPat frames")
    func readsLittleEndian() throws {
        let sample = try #require(FitShowTreadmillDataDecoder.parse(Self.runningFrame))

        // 0x02E2 little-endian is 750; read big-endian it would be 0xE202 = 57858.
        #expect(sample.elapsedSeconds == 750)
        #expect(sample.steps == 2048)   // 0x0800 little-endian, not 0x0008
    }

    @Test("Reads a negative incline as two's complement")
    func readsNegativeIncline() throws {
        let declining = Self.frame(command: 0x51, parameter: 3, payload: [
            0, 0xFB, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ])
        let sample = try #require(FitShowTreadmillDataDecoder.parse(declining))
        #expect(sample.incline == -5)
    }

    @Test("Decodes telemetry from every status that carries it", arguments: [
        (UInt8(1), FitShowTreadmillSample.Status.ended),
        (UInt8(3), FitShowTreadmillSample.Status.running),
        (UInt8(4), FitShowTreadmillSample.Status.stopped),
        (UInt8(10), FitShowTreadmillSample.Status.paused)
    ])
    func decodesTelemetryStatuses(parameter: UInt8, expected: FitShowTreadmillSample.Status) throws {
        let data = Self.frame(command: 0x51, parameter: parameter, payload: [UInt8](repeating: 0, count: 11))
        let sample = try #require(FitShowTreadmillDataDecoder.parse(data))
        #expect(sample.status == expected)
    }

    @Test("Does not attempt telemetry on a status frame that carries none")
    func skipsTelemetryOnShortStatusFrames() throws {
        // A Starting frame carries only the countdown.
        let starting = Self.frame(command: 0x51, parameter: 2, payload: [3])
        #expect(FitShowTreadmillDataDecoder.parse(starting) == nil)

        let fields = try #require(FitShowTreadmillDataDecoder.decode(starting))
        #expect(fields.value("Status") == "Starting")
        #expect(fields.value("Countdown") == "3 s")
        #expect(!fields.hasField("Current Speed"))
    }

    @Test("Distinguishes no heart-rate strap from a reading of zero")
    func reportsMissingHeartRate() throws {
        let noStrap = Self.frame(command: 0x51, parameter: 3, payload: [UInt8](repeating: 0, count: 11))
        let fields = try #require(FitShowTreadmillDataDecoder.decode(noStrap))

        #expect(fields.value("Heart Rate") == "Not detected")
        #expect(fields.detail("Heart Rate")?.contains("no strap paired") == true)
    }

    @Test("Shows both unit readings for a speed the protocol does not label")
    func showsBothUnitReadings() throws {
        let fields = try #require(FitShowTreadmillDataDecoder.decode(Self.runningFrame))

        #expect(fields.value("Current Speed") == "3.2")
        let detail = try #require(fields.detail("Current Speed"))
        #expect(detail.contains("3.2 km/h if metric"))
        #expect(detail.contains("3.2 mph"))
        #expect(detail.contains("5.1 km/h"))   // 3.2 mph converted
    }

    @Test("Formats the fields shown on the characteristic screen")
    func formatsDisplayFields() throws {
        let fields = try #require(FitShowTreadmillDataDecoder.decode(Self.runningFrame))

        #expect(fields.value("Layout") == "FitShow System Status (vendor protocol)")
        #expect(fields.value("Status") == "Running")
        #expect(fields.value("Incline") == "2")
        #expect(fields.value("Elapsed Time") == "12:30")
        #expect(fields.value("Total Distance") == "1.5")
        #expect(fields.value("Total Energy") == "87 kcal")
        #expect(fields.value("Step Count") == "2048 steps")
        #expect(fields.value("Heart Rate") == "132 bpm")
    }

    // MARK: - Other Frame Families

    @Test("Decodes the combined capabilities info frame")
    func decodesCapabilities() throws {
        // Max speed 6.0, min 0.5, incline 0–15, HRC supported, 3 s countdown.
        let capabilities = Self.frame(command: 0x50, parameter: 5, payload: [60, 5, 15, 0, 1, 3])
        let fields = try #require(FitShowTreadmillDataDecoder.decode(capabilities))

        #expect(fields.value("Layout") == "FitShow System Info (vendor protocol)")
        #expect(fields.value("Speed Range") == "0.5 – 6.0")
        #expect(fields.value("Incline Range") == "0 – 15")
        #expect(fields.value("Heart Rate Control") == "Supported")
        #expect(fields.value("Start Countdown") == "3 s")
    }

    @Test("Decodes the factory date, whose year is an offset from 2000")
    func decodesFactoryDate() throws {
        let date = Self.frame(command: 0x50, parameter: 1, payload: [24, 11, 7])
        let fields = try #require(FitShowTreadmillDataDecoder.decode(date))
        #expect(fields.value("Factory Date") == "2024-11-07")
    }

    @Test("Decodes the session totals frame")
    func decodesSessionTotals() throws {
        let totals = Self.frame(command: 0x52, parameter: 0, payload: [
            0xEE, 0x02,     // 750 s
            0x0F, 0x00,     // 1.5
            0x57, 0x00,     // 87 kcal
            0x00, 0x08      // 2048 steps
        ])
        let fields = try #require(FitShowTreadmillDataDecoder.decode(totals))

        #expect(fields.value("Layout") == "FitShow System Data (vendor protocol)")
        #expect(fields.value("Elapsed Time") == "12:30")
        #expect(fields.value("Total Energy") == "87 kcal")
        #expect(fields.value("Step Count") == "2048 steps")
    }

    @Test("Names a console key press rather than dumping it as hex")
    func decodesConsoleKey() throws {
        let key = Self.frame(command: 0x54, parameter: 7)
        let fields = try #require(FitShowTreadmillDataDecoder.decode(key))

        #expect(fields.value("Layout") == "FitShow Console Key (vendor protocol)")
        #expect(fields.value("Console Key") == "Key 7")
    }

    @Test("Falls back to hex for a command byte with no known meaning")
    func fallsBackForUnknownCommands() throws {
        let unknown = Self.frame(command: 0x7A, parameter: 1, payload: [0xAB])
        let fields = try #require(FitShowTreadmillDataDecoder.decode(unknown))

        #expect(fields.value("Layout") == "FitShow Unknown (vendor protocol)")
        #expect(fields.value("Payload") == "AB")
    }

    // MARK: - Registry Tests

    @Test("Routes every FitShow notify characteristic to this decoder", arguments: [
        GATTIdentifier.Characteristic.fitShowNotify,
        GATTIdentifier.Characteristic.fitShowAlternateNotify,
        GATTIdentifier.Characteristic.fitShowNobleProNotify
    ])
    func registryRoutesNotifyCharacteristics(uuid: CBUUID) {
        #expect(GATTDecoderRegistry.hasDedicatedDecoder(for: uuid))

        let fields = GATTDecoderRegistry.decode(Self.runningFrame, for: uuid)
        #expect(fields.value("Status") == "Running")
        #expect(fields.value("Step Count") == "2048 steps")
    }

    @Test("Falls back to a hex dump when a generic UUID carries something else")
    func registryFallsBackForForeignPayloads() {
        // FFF1 is used by plenty of unrelated devices; their data must not be
        // presented as a misparsed treadmill packet.
        let foreign = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let fields = GATTDecoderRegistry.decode(foreign, for: GATTIdentifier.Characteristic.fitShowNotify)

        #expect(!fields.hasField("Layout"))
        #expect(!fields.hasField("Current Speed"))
        #expect(!fields.isEmpty)
    }

    @Test("Names the vendor service and characteristics instead of showing raw UUIDs")
    func namesVendorIdentifiers() {
        #expect(GATTIdentifier.name(for: GATTIdentifier.Service.fitShow) == "FitShow Treadmill (vendor)")
        #expect(GATTIdentifier.name(for: GATTIdentifier.Characteristic.fitShowNotify) == "FitShow Status Stream")
        #expect(GATTIdentifier.name(for: GATTIdentifier.Characteristic.fitShowCommand) == "FitShow Command")
    }

    @Test("Flags an advertised FitShow service as a hint, not a conclusion")
    func flagsAdvertisedService() {
        let advertisement = AdvertisementSnapshot(advertisementData: [
            CBAdvertisementDataServiceUUIDsKey: [GATTIdentifier.Service.fitShow]
        ])

        #expect(advertisement.advertisesFitShowService)
        // Deliberately not promoted to the Fitness Machines section: FFF0 is far
        // too common to treat as proof on its own.
        #expect(!advertisement.advertisesFitnessMachineService)
        #expect(!advertisement.advertisesPitPatTreadmill)
    }
}
