//
//  CharacteristicReading.swift
//  TestDrive
//

import Foundation

/// One value received from a characteristic, with the raw bytes preserved alongside
/// the decode.
struct CharacteristicReading: Identifiable, Sendable {
    /// A stable identity for list diffing.
    let id = UUID()

    /// When the value arrived.
    let date: Date

    /// The raw bytes exactly as delivered by Core Bluetooth.
    let data: Data

    /// The decoded fields.
    let fields: [DecodedField]

    /// Whether the value arrived via a subscription rather than an explicit read.
    let isNotification: Bool

    // MARK: - Initializer

    /// Creates a reading.
    /// - Parameters:
    ///   - data: The raw bytes.
    ///   - fields: The decoded fields.
    ///   - isNotification: `true` when the value arrived via a subscription.
    ///   - date: When the value arrived. Defaults to now.
    init(data: Data, fields: [DecodedField], isNotification: Bool, date: Date = Date()) {
        self.date = date
        self.data = data
        self.fields = fields
        self.isNotification = isNotification
    }
}
