//
//  AdvertisementSnapshot.swift
//  TestDrive
//

import CoreBluetooth

/// Everything a peripheral revealed in its advertising packet, before any connection
/// is made.
///
/// For a fitness machine this is often enough to identify the equipment: the Fitness
/// Machine Service advertises a machine-type bit field that says "stair climber"
/// outright, which is how a TV or phone can offer to connect before pairing.
struct AdvertisementSnapshot: Sendable {

    /// The `CBAdvertisementDataLocalNameKey` value, when present.
    var localName: String?

    /// The services the peripheral says it hosts.
    var serviceUUIDs: [CBUUID]

    /// Services that did not fit in the advertising packet and moved to the scan response.
    var overflowServiceUUIDs: [CBUUID]

    /// Services the peripheral is asking a central to host.
    var solicitedServiceUUIDs: [CBUUID]

    /// Per-service advertising payloads.
    var serviceData: [CBUUID: Data]

    /// The raw manufacturer-specific data, if any.
    var manufacturerData: Data?

    /// The transmit power level in dBm, when advertised.
    var transmitPowerLevel: Int?

    /// Whether the peripheral is accepting connections.
    var isConnectable: Bool?

    // MARK: - Initializer

    /// Creates a snapshot from a Core Bluetooth advertisement dictionary.
    /// - Parameter advertisementData: The dictionary handed to
    ///   `centralManager(_:didDiscover:advertisementData:rssi:)`.
    init(advertisementData: [String: Any]) {
        self.localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        self.serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        self.overflowServiceUUIDs = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] ?? []
        self.solicitedServiceUUIDs = advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID] ?? []
        self.serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] ?? [:]
        self.manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        self.transmitPowerLevel = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
        self.isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue
    }

    // MARK: - Public Helpers

    /// Indicates whether the peripheral advertises the Fitness Machine Service.
    var advertisesFitnessMachineService: Bool {
        let all = serviceUUIDs + overflowServiceUUIDs
        return all.contains(GATTIdentifier.Service.fitnessMachine)
            || serviceData.keys.contains(GATTIdentifier.Service.fitnessMachine)
    }

    /// Indicates whether the peripheral advertises the proprietary PitPat treadmill
    /// service, or names itself as one.
    ///
    /// The name prefix is checked as well as the service UUID because a PitPat pad
    /// usually advertises only its local name (`PitPat-T01`) and reveals service
    /// `FBA0` after connecting.
    var advertisesPitPatTreadmill: Bool {
        let all = serviceUUIDs + overflowServiceUUIDs
        if all.contains(GATTIdentifier.Service.pitPatTreadmill)
            || serviceData.keys.contains(GATTIdentifier.Service.pitPatTreadmill) {
            return true
        }
        guard let localName else { return false }
        return localName.localizedCaseInsensitiveContains(Self.pitPatNamePrefix)
    }

    /// The local-name prefix PitPat treadmills advertise under.
    static let pitPatNamePrefix = "PitPat"

    /// Indicates whether the peripheral advertises a service UUID a FitShow-app
    /// treadmill uses.
    ///
    /// Only ever a hint, never a conclusion: `FFF0` and `FFE0` are generic vendor
    /// UUIDs shared with a great many unrelated BLE devices. Confirmation comes
    /// after connecting, when the notify characteristic produces a frame whose
    /// checksum verifies — see ``FitShowFrame``.
    var advertisesFitShowService: Bool {
        let all = Set(serviceUUIDs + overflowServiceUUIDs).union(serviceData.keys)
        return !all.isDisjoint(with: GATTIdentifier.Service.fitShowServices)
    }

    /// The machine types declared in the Fitness Machine Service advertising data,
    /// e.g. `["Stair Climber"]`.
    var declaredFitnessMachineTypes: [String] {
        guard let data = serviceData[GATTIdentifier.Service.fitnessMachine],
              data.count >= 3 else {
            return []
        }
        var reader = ByteReader(data)
        _ = reader.uint8()
        guard let machineType = reader.uint16() else { return [] }
        return BitFieldFormatter.setFlags(in: machineType, names: FitnessMachineTypeDecoder.machineTypeNames)
    }

    /// The 16-bit company identifier from the manufacturer-specific data, if present.
    var manufacturerCompanyIdentifier: UInt16? {
        guard let manufacturerData, manufacturerData.count >= 2 else { return nil }
        var reader = ByteReader(manufacturerData)
        return reader.uint16()
    }

    /// Every advertised value rendered as decoded fields, for display and logging.
    var fields: [DecodedField] {
        var fields: [DecodedField] = []

        if let localName {
            fields.append(DecodedField(label: "Local Name", value: localName))
        }

        if let isConnectable {
            fields.append(DecodedField(label: "Connectable", value: isConnectable ? "Yes" : "No"))
        }

        if let transmitPowerLevel {
            fields.append(.measurement("Tx Power Level", transmitPowerLevel, unit: "dBm"))
        }

        if !serviceUUIDs.isEmpty {
            fields.append(DecodedField(
                label: "Advertised Services",
                value: serviceUUIDs.map { "\(GATTIdentifier.name(for: $0)) [\($0.uuidString)]" }.joined(separator: "\n")
            ))
        }

        if !overflowServiceUUIDs.isEmpty {
            fields.append(DecodedField(
                label: "Overflow Services",
                value: overflowServiceUUIDs.map { "\(GATTIdentifier.name(for: $0)) [\($0.uuidString)]" }.joined(separator: "\n")
            ))
        }

        if !solicitedServiceUUIDs.isEmpty {
            fields.append(DecodedField(
                label: "Solicited Services",
                value: solicitedServiceUUIDs.map(\.uuidString).joined(separator: "\n")
            ))
        }

        for (uuid, data) in serviceData.sorted(by: { $0.key.uuidString < $1.key.uuidString }) {
            if uuid == GATTIdentifier.Service.fitnessMachine {
                for field in FitnessMachineTypeDecoder.decode(data) {
                    fields.append(DecodedField(
                        label: "FTMS Advertisement — \(field.label)",
                        value: field.value,
                        detail: field.detail
                    ))
                }
            } else {
                fields.append(DecodedField(
                    label: "Service Data — \(GATTIdentifier.name(for: uuid))",
                    value: data.hexDescription,
                    detail: data.printableASCIIDescription
                ))
            }
        }

        if let manufacturerData {
            let companyDetail = manufacturerCompanyIdentifier.map { "company ID 0x\(String(format: "%04X", $0))" }
            fields.append(DecodedField(
                label: "Manufacturer Data",
                value: manufacturerData.hexDescription,
                detail: companyDetail
            ))
        }

        return fields
    }
}
