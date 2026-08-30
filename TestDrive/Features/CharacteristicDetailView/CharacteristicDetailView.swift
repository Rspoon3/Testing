//
//  CharacteristicDetailView.swift
//  TestDrive
//

import CoreBluetooth
import SFSymbols
import SwiftUI
import CoreBluetooth

/// Shows one characteristic in full: its properties, its descriptors, and the
/// history of every value received from it with raw bytes beside each decode.
struct CharacteristicDetailView: View {
    private let characteristic: GATTCharacteristicNode
    private let explorer: BluetoothExplorer

    // MARK: - Initializer

    /// Creates the characteristic screen.
    /// - Parameters:
    ///   - characteristic: The characteristic to inspect.
    ///   - explorer: The explorer used to read and subscribe.
    init(characteristic: GATTCharacteristicNode, explorer: BluetoothExplorer) {
        self.characteristic = characteristic
        self.explorer = explorer
    }

    // MARK: - Body

    var body: some View {
        List {
            metadataSection

            if !characteristic.descriptors.isEmpty {
                descriptorsSection
            }

            readingsSection
        }
        .navigationTitle(characteristic.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private Views

    /// UUID, properties, and the read/subscribe controls.
    private var metadataSection: some View {
        Section {
            LabeledContent("UUID") {
                Text(characteristic.uuid.uuidString)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }

            LabeledContent("Properties", value: characteristic.properties.summary)

            LabeledContent("Values Received", value: "\(characteristic.totalReadingCount)")

            if let error = characteristic.errorDescription {
                LabeledContent("Last Error", value: error)
                    .foregroundStyle(.red)
            }

            if characteristic.properties.isReadable {
                Button("Read Now", symbol: .arrowClockwise) {
                    explorer.read(characteristic)
                }
            }

            if characteristic.properties.isSubscribable {
                Toggle("Subscribed", symbol: .dotRadiowavesUpForward, isOn: Binding(
                    get: { characteristic.isNotifying },
                    set: { explorer.setNotifications($0, for: characteristic) }
                ))
            }
        } header: {
            Label("Characteristic", symbol: .infoCircle)
        } footer: {
            if !GATTIdentifier.isKnown(characteristic.uuid) {
                Text("This UUID is not in the Bluetooth assigned-numbers list, so it is vendor-specific. Values below are shown every plausible way at once — text, bytes, and 16- and 32-bit words — to help identify what the fields mean.")
            }
        }
    }

    /// Descriptors discovered on this characteristic.
    private var descriptorsSection: some View {
        Section {
            ForEach(characteristic.descriptors) { descriptor in
                VStack(alignment: .leading, spacing: 2) {
                    Text(descriptor.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(descriptor.value ?? "No value")
                        .font(.body.monospaced())
                        .textSelection(.enabled)

                    Text(descriptor.uuid.uuidString)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } header: {
            Label("Descriptors", symbol: .textAlignleft)
        }
    }

    /// The retained history of values, newest first.
    private var readingsSection: some View {
        Section {
            if characteristic.readings.isEmpty {
                Text("No values received yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(characteristic.readings) { reading in
                    readingRow(reading)
                }
            }
        } header: {
            Label("Values", symbol: .clock)
        } footer: {
            Text("The most recent \(GATTCharacteristicNode.maximumRetainedReadings) values are kept in memory. The complete history is in the capture log file, which is written as each value arrives.")
        }
    }

    /// One received value: timestamp, raw bytes, and decoded fields.
    private func readingRow(_ reading: CharacteristicReading) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(reading.date.formatted(.dateTime.hour().minute().second()))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if reading.isNotification {
                    Image(symbol: .dotRadiowavesUpForward)
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Text(reading.data.hexDescription)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)

            ForEach(reading.fields) { field in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(field.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(field.value)
                        .font(.caption.monospacedDigit())
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
