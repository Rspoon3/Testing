//
//  GATTDecoderRegistry.swift
//  TestDrive
//

import CoreBluetooth

/// Routes a raw characteristic value to the decoder that understands it.
///
/// Anything without a specification-aware decoder falls through to
/// ``RawValueInspector``, so no value is ever dropped on the floor.
enum GATTDecoderRegistry {

    // MARK: - Public Helpers

    /// Decodes a characteristic value.
    /// - Parameters:
    ///   - data: The raw characteristic value.
    ///   - uuid: The characteristic UUID.
    /// - Returns: The decoded fields.
    static func decode(_ data: Data, for uuid: CBUUID) -> [DecodedField] {
        typealias Characteristic = GATTIdentifier.Characteristic

        switch uuid {
        case Characteristic.stairClimberData:
            return StairClimberDataDecoder.decode(data)

        case Characteristic.stepClimberData:
            return StepClimberDataDecoder.decode(data)

        case Characteristic.crossTrainerData:
            return CrossTrainerDataDecoder.decode(data)

        case Characteristic.fitnessMachineFeature:
            return FitnessMachineFeatureDecoder.decode(data)

        case Characteristic.fitnessMachineStatus:
            return FitnessMachineStatusDecoder.decode(data)

        case Characteristic.trainingStatus:
            return TrainingStatusDecoder.decode(data)

        case Characteristic.supportedSpeedRange,
             Characteristic.supportedInclinationRange,
             Characteristic.supportedResistanceLevelRange,
             Characteristic.supportedHeartRateRange,
             Characteristic.supportedPowerRange:
            return SupportedRangeDecoder.decode(data, uuid: uuid)

        case Characteristic.heartRateMeasurement:
            return HeartRateMeasurementDecoder.decode(data)

        case Characteristic.batteryLevel:
            return DeviceInformationDecoder.decodeBatteryLevel(data)

        case Characteristic.pnpID:
            return DeviceInformationDecoder.decodePnPID(data)

        case Characteristic.systemID:
            return DeviceInformationDecoder.decodeSystemID(data)

        case Characteristic.appearance:
            return DeviceInformationDecoder.decodeAppearance(data)

        case Characteristic.bodySensorLocation:
            return DeviceInformationDecoder.decodeBodySensorLocation(data)

        case Characteristic.peripheralPreferredConnectionParameters:
            return DeviceInformationDecoder.decodePreferredConnectionParameters(data)

        case Characteristic.deviceName,
             Characteristic.modelNumber,
             Characteristic.serialNumber,
             Characteristic.firmwareRevision,
             Characteristic.hardwareRevision,
             Characteristic.softwareRevision,
             Characteristic.manufacturerName:
            guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
                return RawValueInspector.inspect(data)
            }
            return [DecodedField(label: GATTIdentifier.name(for: uuid), value: text)]

        default:
            return RawValueInspector.inspect(data)
        }
    }

    /// Indicates whether the app has a specification-aware decoder for a characteristic.
    /// - Parameter uuid: The characteristic UUID.
    /// - Returns: `true` when a dedicated decoder exists, `false` when the value
    ///   falls through to ``RawValueInspector``.
    static func hasDedicatedDecoder(for uuid: CBUUID) -> Bool {
        dedicatedUUIDs.contains(uuid)
    }

    // MARK: - Private Helpers

    private static let dedicatedUUIDs: Set<CBUUID> = {
        typealias Characteristic = GATTIdentifier.Characteristic
        return [
            Characteristic.stairClimberData,
            Characteristic.stepClimberData,
            Characteristic.crossTrainerData,
            Characteristic.fitnessMachineFeature,
            Characteristic.fitnessMachineStatus,
            Characteristic.trainingStatus,
            Characteristic.supportedSpeedRange,
            Characteristic.supportedInclinationRange,
            Characteristic.supportedResistanceLevelRange,
            Characteristic.supportedHeartRateRange,
            Characteristic.supportedPowerRange,
            Characteristic.heartRateMeasurement,
            Characteristic.batteryLevel,
            Characteristic.pnpID,
            Characteristic.systemID,
            Characteristic.appearance,
            Characteristic.bodySensorLocation,
            Characteristic.peripheralPreferredConnectionParameters,
            Characteristic.deviceName,
            Characteristic.modelNumber,
            Characteristic.serialNumber,
            Characteristic.firmwareRevision,
            Characteristic.hardwareRevision,
            Characteristic.softwareRevision,
            Characteristic.manufacturerName
        ]
    }()
}
