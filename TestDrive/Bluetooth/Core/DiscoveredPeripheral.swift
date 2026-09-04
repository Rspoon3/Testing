//
//  DiscoveredPeripheral.swift
//  TestDrive
//

import CoreBluetooth

/// A peripheral seen during a scan, together with the latest advertisement and
/// signal strength.
@Observable
final class DiscoveredPeripheral: Identifiable {

    /// The Core Bluetooth peripheral.
    let peripheral: CBPeripheral

    /// The peripheral's identifier, stable for the lifetime of the pairing.
    var id: UUID { peripheral.identifier }

    /// The most recent advertisement received.
    var advertisement: AdvertisementSnapshot

    /// The most recent RSSI reading, in dBm.
    var signalStrength: Int

    /// How many advertising packets have been seen from this peripheral.
    var advertisementCount = 1

    /// When the peripheral was last seen.
    var lastSeen = Date()

    /// The best available display name: the advertised local name, then the
    /// peripheral's cached name, then the identifier.
    var displayName: String {
        if let localName = advertisement.localName, !localName.isEmpty {
            return localName
        }
        if let name = peripheral.name, !name.isEmpty {
            return name
        }
        return "Unnamed (\(peripheral.identifier.uuidString.prefix(8)))"
    }

    /// Whether this peripheral looks like fitness equipment this app can decode,
    /// either through the standard Fitness Machine Service or a recognised vendor
    /// protocol.
    var isFitnessMachine: Bool {
        advertisement.advertisesFitnessMachineService || isPitPatTreadmill
    }

    /// Whether this peripheral is a PitPat-app treadmill or walking pad, which
    /// speaks a vendor protocol instead of the Fitness Machine Service.
    var isPitPatTreadmill: Bool {
        if advertisement.advertisesPitPatTreadmill { return true }
        guard let name = peripheral.name else { return false }
        return name.localizedCaseInsensitiveContains(AdvertisementSnapshot.pitPatNamePrefix)
    }

    // MARK: - Initializer

    /// Creates a record for a newly discovered peripheral.
    /// - Parameters:
    ///   - peripheral: The Core Bluetooth peripheral.
    ///   - advertisement: The advertisement it was discovered with.
    ///   - signalStrength: The RSSI at discovery, in dBm.
    init(peripheral: CBPeripheral, advertisement: AdvertisementSnapshot, signalStrength: Int) {
        self.peripheral = peripheral
        self.advertisement = advertisement
        self.signalStrength = signalStrength
    }

    // MARK: - Public Helpers

    /// Merges a fresh advertisement into this record.
    ///
    /// Advertising packets and scan responses carry different subsets of the same
    /// data, so a later packet that omits a field must not erase what an earlier one
    /// revealed. Fields are therefore merged rather than replaced.
    /// - Parameters:
    ///   - advertisement: The newly received advertisement.
    ///   - signalStrength: The RSSI of the new packet, in dBm.
    func update(advertisement: AdvertisementSnapshot, signalStrength: Int) {
        self.signalStrength = signalStrength
        self.advertisementCount += 1
        self.lastSeen = Date()
        self.advertisement = merge(existing: self.advertisement, incoming: advertisement)
    }

    // MARK: - Private Helpers

    /// Combines two advertisements, preferring the incoming value where it is present.
    private func merge(existing: AdvertisementSnapshot, incoming: AdvertisementSnapshot) -> AdvertisementSnapshot {
        var merged = incoming

        if merged.localName == nil { merged.localName = existing.localName }
        if merged.manufacturerData == nil { merged.manufacturerData = existing.manufacturerData }
        if merged.transmitPowerLevel == nil { merged.transmitPowerLevel = existing.transmitPowerLevel }
        if merged.isConnectable == nil { merged.isConnectable = existing.isConnectable }
        if merged.serviceUUIDs.isEmpty { merged.serviceUUIDs = existing.serviceUUIDs }
        if merged.overflowServiceUUIDs.isEmpty { merged.overflowServiceUUIDs = existing.overflowServiceUUIDs }
        if merged.solicitedServiceUUIDs.isEmpty { merged.solicitedServiceUUIDs = existing.solicitedServiceUUIDs }

        merged.serviceData = existing.serviceData.merging(incoming.serviceData) { _, new in new }

        return merged
    }
}
