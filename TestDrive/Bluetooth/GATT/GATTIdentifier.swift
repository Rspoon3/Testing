//
//  GATTIdentifier.swift
//  TestDrive
//

import CoreBluetooth

/// The assigned-number catalogue for the Bluetooth services and characteristics this
/// app knows how to name and decode.
///
/// Anything missing from the catalogue still shows up in the UI — it is simply
/// labelled by its raw UUID and rendered as a hex dump instead.
enum GATTIdentifier {

    // MARK: - Services

    /// Standard Bluetooth SIG services.
    enum Service {
        static let genericAccess = CBUUID(string: "1800")
        static let genericAttribute = CBUUID(string: "1801")
        static let deviceInformation = CBUUID(string: "180A")
        static let heartRate = CBUUID(string: "180D")
        static let battery = CBUUID(string: "180F")
        static let cyclingSpeedAndCadence = CBUUID(string: "1816")
        static let cyclingPower = CBUUID(string: "1818")
        static let userData = CBUUID(string: "181C")
        static let fitnessMachine = CBUUID(string: "1826")

        /// Nordic Semiconductor Secure DFU, present on modules built around a
        /// Nordic SoC. Its appearance identifies the controller family and means
        /// the machine accepts firmware updates over the air.
        static let nordicSecureDFU = CBUUID(string: "FE59")

        /// The proprietary service used by PitPat-app treadmills and walking pads,
        /// such as the SupeRun `BA10-B`.
        ///
        /// These machines do **not** implement the Fitness Machine Service at all.
        /// They advertise as `PitPat-T01` and carry all telemetry and control
        /// through this one vendor service, which is why the scanner has to be left
        /// unfiltered to find them.
        static let pitPatTreadmill = CBUUID(string: "FBA0")

        /// The primary service used by FitShow-app treadmills, such as the maksone
        /// `SL-Z01` (Ningbo Kangruida `AMA005726`).
        ///
        /// `FFF0` is a generic vendor UUID that plenty of unrelated cheap BLE
        /// devices also use, so its presence alone is only a hint. Proof comes from
        /// the notify characteristic: a FitShow frame is self-validating, with a
        /// fixed header, footer, and XOR checksum.
        static let fitShow = CBUUID(string: "FFF0")

        /// The alternate FitShow service UUID, used by some firmware builds.
        static let fitShowAlternate = CBUUID(string: "FFE0")

        /// The FitShow service UUID used by NoblePro-branded machines.
        static let fitShowNoblePro = CBUUID(string: "AE00")

        /// Every service UUID a FitShow machine is known to expose.
        static let fitShowServices: Set<CBUUID> = [fitShow, fitShowAlternate, fitShowNoblePro]
    }

    // MARK: - Characteristics

    /// Standard Bluetooth SIG characteristics.
    enum Characteristic {
        // Generic Access / Attribute
        static let deviceName = CBUUID(string: "2A00")
        static let appearance = CBUUID(string: "2A01")
        static let peripheralPreferredConnectionParameters = CBUUID(string: "2A04")
        static let serviceChanged = CBUUID(string: "2A05")

        // Battery
        static let batteryLevel = CBUUID(string: "2A19")

        // Device Information
        static let systemID = CBUUID(string: "2A23")
        static let modelNumber = CBUUID(string: "2A24")
        static let serialNumber = CBUUID(string: "2A25")
        static let firmwareRevision = CBUUID(string: "2A26")
        static let hardwareRevision = CBUUID(string: "2A27")
        static let softwareRevision = CBUUID(string: "2A28")
        static let manufacturerName = CBUUID(string: "2A29")
        static let regulatoryCertificationDataList = CBUUID(string: "2A2A")
        static let pnpID = CBUUID(string: "2A50")

        // Heart Rate
        static let heartRateMeasurement = CBUUID(string: "2A37")
        static let bodySensorLocation = CBUUID(string: "2A38")

        // Fitness Machine Service
        static let fitnessMachineFeature = CBUUID(string: "2ACC")
        static let treadmillData = CBUUID(string: "2ACD")
        static let crossTrainerData = CBUUID(string: "2ACE")
        static let stepClimberData = CBUUID(string: "2ACF")
        static let stairClimberData = CBUUID(string: "2AD0")
        static let rowerData = CBUUID(string: "2AD1")
        static let indoorBikeData = CBUUID(string: "2AD2")
        static let trainingStatus = CBUUID(string: "2AD3")
        static let supportedSpeedRange = CBUUID(string: "2AD4")
        static let supportedInclinationRange = CBUUID(string: "2AD5")
        static let supportedResistanceLevelRange = CBUUID(string: "2AD6")
        static let supportedHeartRateRange = CBUUID(string: "2AD7")
        static let supportedPowerRange = CBUUID(string: "2AD8")
        static let fitnessMachineControlPoint = CBUUID(string: "2AD9")
        static let fitnessMachineStatus = CBUUID(string: "2ADA")

        /// Nordic buttonless DFU control point, used to reboot a device into its
        /// bootloader.
        static let nordicButtonlessDFU = CBUUID(string: "8EC90003-F315-4F60-9FB8-838830DAEA50")

        // PitPat vendor service

        /// The PitPat command characteristic, which accepts 23-byte start, stop,
        /// pause, and set-speed frames. Never written by this app.
        static let pitPatCommand = CBUUID(string: "FBA1")

        /// The PitPat state characteristic, which notifies a 31-byte telemetry
        /// frame carrying speed, distance, steps, calories, and elapsed time.
        static let pitPatState = CBUUID(string: "FBA2")

        // FitShow vendor service. Each service variant pairs one write
        // characteristic with one notify characteristic.

        /// The FitShow command characteristic on an `FFF0` machine. Never written
        /// by this app.
        static let fitShowCommand = CBUUID(string: "FFF2")

        /// The FitShow notify characteristic on an `FFF0` machine, which streams the
        /// framed status and sport-data packets.
        static let fitShowNotify = CBUUID(string: "FFF1")

        /// The FitShow command characteristic on an `FFE0` machine.
        static let fitShowAlternateCommand = CBUUID(string: "FFE1")

        /// The FitShow notify characteristic on an `FFE0` machine.
        static let fitShowAlternateNotify = CBUUID(string: "FFE4")

        /// The FitShow command characteristic on a NoblePro machine.
        static let fitShowNobleProCommand = CBUUID(string: "AE01")

        /// The FitShow notify characteristic on a NoblePro machine.
        static let fitShowNobleProNotify = CBUUID(string: "AE02")

        /// Every characteristic a FitShow machine streams framed telemetry on.
        static let fitShowNotifyCharacteristics: Set<CBUUID> = [
            fitShowNotify,
            fitShowAlternateNotify,
            fitShowNobleProNotify
        ]
    }

    // MARK: - Descriptors

    /// Standard Bluetooth SIG descriptors.
    enum Descriptor {
        static let characteristicExtendedProperties = CBUUID(string: "2900")
        static let characteristicUserDescription = CBUUID(string: "2901")
        static let clientCharacteristicConfiguration = CBUUID(string: "2902")
        static let serverCharacteristicConfiguration = CBUUID(string: "2903")
        static let characteristicPresentationFormat = CBUUID(string: "2904")
        static let characteristicAggregateFormat = CBUUID(string: "2905")
    }

    // MARK: - Public Helpers

    /// The characteristics that carry live workout telemetry for a fitness machine.
    ///
    /// A stair machine may report through any of these depending on how its firmware
    /// classifies itself, so the app subscribes to all of them and shows whichever
    /// actually produces data.
    static let fitnessMachineDataCharacteristics: Set<CBUUID> = [
        Characteristic.treadmillData,
        Characteristic.crossTrainerData,
        Characteristic.stepClimberData,
        Characteristic.stairClimberData,
        Characteristic.rowerData,
        Characteristic.indoorBikeData
    ]

    /// Returns a human-readable name for a service, characteristic, or descriptor UUID.
    /// - Parameter uuid: The UUID to name.
    /// - Returns: The Bluetooth SIG name when known, otherwise a `"Unknown (…)"` label
    ///   containing the raw UUID string.
    static func name(for uuid: CBUUID) -> String {
        if let name = names[uuid] {
            return name
        }
        return "Unknown (\(uuid.uuidString))"
    }

    /// Indicates whether the app has a specification-aware name for the given UUID.
    /// - Parameter uuid: The UUID to check.
    /// - Returns: `true` when the UUID appears in the assigned-number catalogue.
    static func isKnown(_ uuid: CBUUID) -> Bool {
        names[uuid] != nil
    }

    // MARK: - Private Helpers

    private static let names: [CBUUID: String] = [
        Service.genericAccess: "Generic Access",
        Service.genericAttribute: "Generic Attribute",
        Service.deviceInformation: "Device Information",
        Service.heartRate: "Heart Rate",
        Service.battery: "Battery",
        Service.cyclingSpeedAndCadence: "Cycling Speed and Cadence",
        Service.cyclingPower: "Cycling Power",
        Service.userData: "User Data",
        Service.fitnessMachine: "Fitness Machine",
        Service.nordicSecureDFU: "Nordic Secure DFU",
        Characteristic.nordicButtonlessDFU: "Nordic Buttonless DFU Control Point",

        Service.pitPatTreadmill: "PitPat Treadmill (vendor)",
        Characteristic.pitPatCommand: "PitPat Command",
        Characteristic.pitPatState: "PitPat Treadmill State",

        Service.fitShow: "FitShow Treadmill (vendor)",
        Service.fitShowAlternate: "FitShow Treadmill (vendor, alternate)",
        Service.fitShowNoblePro: "FitShow Treadmill (vendor, NoblePro)",
        Characteristic.fitShowCommand: "FitShow Command",
        Characteristic.fitShowNotify: "FitShow Status Stream",
        Characteristic.fitShowAlternateCommand: "FitShow Command (alternate)",
        Characteristic.fitShowAlternateNotify: "FitShow Status Stream (alternate)",
        Characteristic.fitShowNobleProCommand: "FitShow Command (NoblePro)",
        Characteristic.fitShowNobleProNotify: "FitShow Status Stream (NoblePro)",

        Characteristic.deviceName: "Device Name",
        Characteristic.appearance: "Appearance",
        Characteristic.peripheralPreferredConnectionParameters: "Preferred Connection Parameters",
        Characteristic.serviceChanged: "Service Changed",
        Characteristic.batteryLevel: "Battery Level",
        Characteristic.systemID: "System ID",
        Characteristic.modelNumber: "Model Number",
        Characteristic.serialNumber: "Serial Number",
        Characteristic.firmwareRevision: "Firmware Revision",
        Characteristic.hardwareRevision: "Hardware Revision",
        Characteristic.softwareRevision: "Software Revision",
        Characteristic.manufacturerName: "Manufacturer Name",
        Characteristic.regulatoryCertificationDataList: "Regulatory Certification Data",
        Characteristic.pnpID: "PnP ID",
        Characteristic.heartRateMeasurement: "Heart Rate Measurement",
        Characteristic.bodySensorLocation: "Body Sensor Location",

        Characteristic.fitnessMachineFeature: "Fitness Machine Feature",
        Characteristic.treadmillData: "Treadmill Data",
        Characteristic.crossTrainerData: "Cross Trainer Data",
        Characteristic.stepClimberData: "Step Climber Data",
        Characteristic.stairClimberData: "Stair Climber Data",
        Characteristic.rowerData: "Rower Data",
        Characteristic.indoorBikeData: "Indoor Bike Data",
        Characteristic.trainingStatus: "Training Status",
        Characteristic.supportedSpeedRange: "Supported Speed Range",
        Characteristic.supportedInclinationRange: "Supported Inclination Range",
        Characteristic.supportedResistanceLevelRange: "Supported Resistance Level Range",
        Characteristic.supportedHeartRateRange: "Supported Heart Rate Range",
        Characteristic.supportedPowerRange: "Supported Power Range",
        Characteristic.fitnessMachineControlPoint: "Fitness Machine Control Point",
        Characteristic.fitnessMachineStatus: "Fitness Machine Status",

        Descriptor.characteristicExtendedProperties: "Extended Properties",
        Descriptor.characteristicUserDescription: "User Description",
        Descriptor.clientCharacteristicConfiguration: "Client Characteristic Configuration",
        Descriptor.serverCharacteristicConfiguration: "Server Characteristic Configuration",
        Descriptor.characteristicPresentationFormat: "Presentation Format",
        Descriptor.characteristicAggregateFormat: "Aggregate Format"
    ]
}
