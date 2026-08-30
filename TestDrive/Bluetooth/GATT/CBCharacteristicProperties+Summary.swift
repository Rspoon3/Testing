//
//  CBCharacteristicProperties+Summary.swift
//  TestDrive
//

import CoreBluetooth

extension CBCharacteristicProperties {
    /// The individual GATT property flags set on this characteristic, as short labels.
    var labels: [String] {
        var labels: [String] = []
        if contains(.broadcast) { labels.append("Broadcast") }
        if contains(.read) { labels.append("Read") }
        if contains(.writeWithoutResponse) { labels.append("Write No Rsp") }
        if contains(.write) { labels.append("Write") }
        if contains(.notify) { labels.append("Notify") }
        if contains(.indicate) { labels.append("Indicate") }
        if contains(.authenticatedSignedWrites) { labels.append("Signed Write") }
        if contains(.extendedProperties) { labels.append("Extended") }
        if contains(.notifyEncryptionRequired) { labels.append("Notify (Enc)") }
        if contains(.indicateEncryptionRequired) { labels.append("Indicate (Enc)") }
        return labels
    }

    /// A comma-separated summary of the property flags, suitable for a subtitle.
    var summary: String {
        labels.isEmpty ? "No properties" : labels.joined(separator: ", ")
    }

    /// Indicates whether the characteristic's value can be read on demand.
    var isReadable: Bool { contains(.read) }

    /// Indicates whether the characteristic can push value updates to a subscriber.
    var isSubscribable: Bool {
        contains(.notify)
            || contains(.indicate)
            || contains(.notifyEncryptionRequired)
            || contains(.indicateEncryptionRequired)
    }
}
