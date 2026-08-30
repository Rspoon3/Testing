//
//  PeripheralDetailView.swift
//  TestDrive
//

import SFSymbols
import SwiftUI
import CoreBluetooth

/// Connects to one peripheral, walks its entire GATT database, and shows everything
/// it produces — decoded where the specification allows, raw where it does not.
struct PeripheralDetailView: View {
    @State private var viewModel: PeripheralDetailViewModel

    // MARK: - Initializer

    /// Creates the detail screen.
    /// - Parameter viewModel: The view model for the peripheral being inspected.
    init(viewModel: PeripheralDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        List {
            statusSection

            if let telemetry = viewModel.liveTelemetry {
                liveTelemetrySection(telemetry)
            }

            if !viewModel.identityFields.isEmpty {
                fieldSection(
                    title: "Machine Identity",
                    symbol: .tagFill,
                    fields: viewModel.identityFields
                )
            }

            if !viewModel.capabilityFields.isEmpty {
                fieldSection(
                    title: "Declared Capabilities",
                    symbol: .checkmarkCircleFill,
                    fields: viewModel.capabilityFields,
                    footer: "The machine's own statement of which metrics it can report and which targets it will accept."
                )
            }

            advertisementSection
            servicesSection
            logSection
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let logFileURL = viewModel.logFileURL {
                    ShareLink(item: logFileURL) {
                        Image(symbol: .squareAndArrowUp)
                    }
                }
            }
        }
        .task {
            viewModel.connectIfNeeded()
        }
    }

    // MARK: - Private Views

    /// Connection state, discovery counts, and the connect/disconnect controls.
    private var statusSection: some View {
        Section {
            LabeledContent("Status", value: viewModel.connectionState.label)

            if viewModel.isReady {
                LabeledContent("Discovered", value: viewModel.discoverySummary)
            }

            LabeledContent("Signal", value: "\(viewModel.peripheral.signalStrength) dBm")

            if viewModel.connectionState == .disconnected {
                Button("Connect", symbol: .antennaRadiowavesLeftAndRight) {
                    viewModel.reconnect()
                }
            } else {
                Button("Disconnect", symbol: .stopCircle, role: .destructive) {
                    viewModel.disconnect()
                }
            }

            if case .failed = viewModel.connectionState {
                Button("Try Again", symbol: .arrowClockwise) {
                    viewModel.reconnect()
                }
            }

            if viewModel.isReady {
                Button("Re-read Everything", symbol: .arrowTriangle2Circlepath) {
                    viewModel.refreshAll()
                }

                if viewModel.supportsControlPoint {
                    Button("Request Machine Control", symbol: .boltHorizontalCircle) {
                        viewModel.requestControl()
                    }
                }
            }
        } header: {
            Label("Connection", symbol: .dotRadiowavesLeftAndRight)
        } footer: {
            if viewModel.supportsControlPoint && viewModel.isReady {
                Text("Requesting control writes op code 0x00 to the Fitness Machine Control Point. It opens the control channel without changing anything about the workout in progress, and some machines withhold data until a client asks.")
            }
        }
    }

    /// The live workout telemetry from whichever FTMS data characteristic is active.
    private func liveTelemetrySection(
        _ telemetry: (node: GATTCharacteristicNode, reading: CharacteristicReading)
    ) -> some View {
        Section {
            ForEach(telemetry.reading.fields) { field in
                fieldRow(field)
            }
        } header: {
            HStack {
                Label("Live — \(telemetry.node.name)", symbol: .figureStairStepper)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("^[\(telemetry.node.totalReadingCount) update](inflect: true)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Raw: \(telemetry.reading.data.hexDescription)")
                .font(.caption2.monospaced())
        }
    }

    /// Everything the peripheral revealed before connecting.
    private var advertisementSection: some View {
        Section {
            ForEach(viewModel.peripheral.advertisement.fields) { field in
                fieldRow(field)
            }
        } header: {
            Label("Advertisement", symbol: .waveform)
        }
    }

    /// The full GATT tree, one navigable row per characteristic.
    private var servicesSection: some View {
        ForEach(viewModel.services) { service in
            Section {
                if service.characteristics.isEmpty {
                    Text("No characteristics discovered.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(service.characteristics) { characteristic in
                        NavigationLink {
                            CharacteristicDetailView(
                                characteristic: characteristic,
                                explorer: viewModel.explorer
                            )
                        } label: {
                            characteristicRow(characteristic)
                        }
                    }
                }
            } header: {
                Label(service.name, symbol: GATTIdentifier.isKnown(service.uuid) ? .listBullet : .cube)
            } footer: {
                Text(service.uuid.uuidString)
                    .font(.caption2.monospaced())
            }
        }
    }

    /// A summary row for one characteristic.
    private func characteristicRow(_ characteristic: GATTCharacteristicNode) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(characteristic.name)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if characteristic.isNotifying {
                    Image(symbol: .dotRadiowavesUpForward)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Text(characteristic.properties.summary)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if let reading = characteristic.latestReading {
                Text(summary(of: reading))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else if let error = characteristic.errorDescription {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("No value yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// The live log tail plus the share affordance.
    private var logSection: some View {
        Section {
            if let logFileURL = viewModel.logFileURL {
                ShareLink(item: logFileURL) {
                    Label("Share Capture Log", symbol: .squareAndArrowUp)
                }

                LabeledContent("File", value: logFileURL.lastPathComponent)
                    .font(.caption)
            }

            if viewModel.recentLogLines.isEmpty {
                Text("No events yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(viewModel.recentLogLines.suffix(12).enumerated()), id: \.offset) { entry in
                    Text(entry.element)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Capture Log", symbol: .docText)
        } footer: {
            Text("Every advertisement, discovery, read, and notification is appended to a text file on disk as it happens, with raw bytes alongside each decode. Share it any time — the file is complete up to this moment, and the session does not need to end first.")
        }
    }

    /// A single decoded field row.
    private func fieldRow(_ field: DecodedField) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(field.label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(field.value)
                .font(.body.monospacedDigit())
                .textSelection(.enabled)

            if let detail = field.detail {
                Text(detail)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A section of decoded fields with a title and optional footer.
    private func fieldSection(
        title: String,
        symbol: SFSymbol,
        fields: [DecodedField],
        footer: String? = nil
    ) -> some View {
        Section {
            ForEach(fields) { field in
                fieldRow(field)
            }
        } header: {
            Label(title, symbol: symbol)
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }

    // MARK: - Private Helpers

    /// A compact one-line summary of a reading for the characteristic list.
    private func summary(of reading: CharacteristicReading) -> String {
        let interesting = reading.fields.filter { $0.label != "Flags" }
        guard let first = interesting.first else {
            return reading.data.hexDescription
        }

        if interesting.count == 1 {
            return "\(first.label): \(first.value)"
        }
        return "\(first.label): \(first.value)  +\(interesting.count - 1) more"
    }
}
