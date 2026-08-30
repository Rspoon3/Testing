//
//  FitnessMachineDecoderTests.swift
//  TestDriveTests
//

import Foundation
import Testing
@testable import TestDrive

/// Checks the Fitness Machine Service characteristics that describe the machine
/// rather than its live telemetry.
@Suite("Fitness machine characteristics")
struct FitnessMachineDecoderTests {

    // MARK: - Fitness Machine Feature

    @Test("The captured feature payload lists exactly what the machine declares")
    func capturedFeaturePayload() {
        let fields = FitnessMachineFeatureDecoder.decode(CapturedPackets.fitnessMachineFeature)
        let features = fields.value("Machine Features")

        // 0x00003F50 — bits 4, 6, 8, 9, 10, 11, 12, 13.
        #expect(features?.contains("Elevation Gain") == true)
        #expect(features?.contains("Step Count") == true)
        #expect(features?.contains("Stride Count") == true)
        #expect(features?.contains("Expended Energy") == true)
        #expect(features?.contains("Heart Rate Measurement") == true)
        #expect(features?.contains("Metabolic Equivalent") == true)
        #expect(features?.contains("Elapsed Time") == true)
        #expect(features?.contains("Remaining Time") == true)

        // Not declared, and their absence is what makes the machine's telemetry
        // layout make sense.
        #expect(features?.contains("Average Speed") == false)
        #expect(features?.contains("Total Distance") == false)
        #expect(features?.contains("Inclination") == false)
        #expect(features?.contains("Resistance Level") == false)
        #expect(features?.contains("Power Measurement") == false)
    }

    @Test("The machine declares no settable targets")
    func noTargetSettingFeatures() {
        let fields = FitnessMachineFeatureDecoder.decode(CapturedPackets.fitnessMachineFeature)

        #expect(fields.value("Target Setting Features") == "None declared")
        #expect(fields.detail("Target Setting Features") == "0x00000000")
    }

    @Test("The raw feature bit field is preserved as detail")
    func featureBitFieldPreserved() {
        let fields = FitnessMachineFeatureDecoder.decode(CapturedPackets.fitnessMachineFeature)

        #expect(fields.detail("Machine Features") == "0x00003F50")
    }

    @Test("A feature payload shorter than four bytes reports an error")
    func truncatedFeaturePayload() {
        #expect(FitnessMachineFeatureDecoder.decode(Data([0x50, 0x3F])).value("Error") != nil)
    }

    // MARK: - Training Status

    @Test("The captured training status decodes to idle with no flags")
    func capturedTrainingStatus() {
        let fields = TrainingStatusDecoder.decode(CapturedPackets.trainingStatusIdle)

        #expect(fields.value("Training Status") == "Idle")
        #expect(fields.detail("Training Status") == "0x01")
    }

    @Test("An empty flag set reads as None set rather than blank")
    func emptyFlagsAreNamed() {
        let fields = TrainingStatusDecoder.decode(CapturedPackets.trainingStatusIdle)

        #expect(fields.value("Flags") == "None set")
    }

    @Test("A training status string is decoded when its flag is set")
    func trainingStatusString() {
        // Synthesised: flag bit 0 set, status 0x0D (manual mode), then UTF-8.
        let payload = Data([0x01, 0x0D]) + Data("Quick Start".utf8)
        let fields = TrainingStatusDecoder.decode(payload)

        #expect(fields.value("Training Status") == "Manual Mode (Quick Start)")
        #expect(fields.value("Training Status String") == "Quick Start")
    }

    @Test("An unknown training status value is not invented")
    func unknownTrainingStatus() {
        let fields = TrainingStatusDecoder.decode(Data([0x00, 0x7F]))

        #expect(fields.value("Training Status") == "Unknown or vendor-specific")
    }

    // MARK: - Fitness Machine Status

    @Test("The captured status notification decodes to a user start")
    func capturedFitnessMachineStatus() {
        let fields = FitnessMachineStatusDecoder.decode(CapturedPackets.fitnessMachineStatusStarted)

        #expect(fields.value("Status") == "Started or Resumed by the User")
        #expect(fields.detail("Status") == "op code 0x04")
    }

    @Test("Stop and pause are distinguished by their parameter")
    func stopAndPauseParameter() {
        let stopped = FitnessMachineStatusDecoder.decode(Data([0x02, 0x01]))
        let paused = FitnessMachineStatusDecoder.decode(Data([0x02, 0x02]))

        #expect(stopped.value("Stop or Pause Reason") == "Stopped")
        #expect(paused.value("Stop or Pause Reason") == "Paused")
    }

    @Test("Control permission lost is recognised")
    func controlPermissionLost() {
        #expect(FitnessMachineStatusDecoder.decode(Data([0xFF])).value("Status") == "Control Permission Lost")
    }

    @Test("An empty status payload reports an error")
    func emptyStatusPayload() {
        #expect(FitnessMachineStatusDecoder.decode(Data()).value("Error") != nil)
    }

    // MARK: - Advertised Machine Type

    @Test("Advertised service data identifies a stair climber")
    func advertisedStairClimber() {
        // Reconstructed from the capture, which logged "Fitness Machine Available"
        // and "Stair Climber": flags 0x01, machine type bit 3.
        let fields = FitnessMachineTypeDecoder.decode(Data([0x01, 0x08, 0x00]))

        #expect(fields.value("Service Data Flags") == "Fitness Machine Available")
        #expect(fields.value("Fitness Machine Type") == "Stair Climber")
    }

    @Test("Multiple advertised machine types are all listed")
    func multipleMachineTypes() {
        // Synthesised: treadmill and cross trainer bits both set.
        let fields = FitnessMachineTypeDecoder.decode(Data([0x01, 0x03, 0x00]))
        let types = fields.value("Fitness Machine Type")

        #expect(types?.contains("Treadmill") == true)
        #expect(types?.contains("Cross Trainer") == true)
    }

    @Test("An unavailable machine is reported as such")
    func machineUnavailable() {
        let fields = FitnessMachineTypeDecoder.decode(Data([0x00, 0x08, 0x00]))

        #expect(fields.value("Service Data Flags") == "Fitness Machine Not Available")
    }
}
