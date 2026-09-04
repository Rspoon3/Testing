//
//  ScannerView.swift
//  TestDrive
//

import SFSymbols
import SwiftUI

/// Lists every Bluetooth Low Energy peripheral in range, with anything advertising
/// the Fitness Machine Service pulled to the top.
struct ScannerView: View {
    @State private var viewModel = ScannerViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if let message = viewModel.unavailableMessage {
                    unavailableSection(message: message)
                }

                if !viewModel.fitnessMachines.isEmpty {
                    Section {
                        ForEach(viewModel.fitnessMachines) { peripheral in
                            peripheralLink(peripheral)
                        }
                    } header: {
                        Label("Fitness Machines", symbol: .figureStairStepper)
                    } footer: {
                        Text("These peripherals either advertise the standard Fitness Machine Service or match a vendor protocol this app decodes, so their workout data can be read without any vendor SDK.")
                    }
                }

                Section {
                    if viewModel.otherPeripherals.isEmpty {
                        Text(viewModel.isScanning ? "Scanning…" : "No other devices found.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.otherPeripherals) { peripheral in
                            peripheralLink(peripheral)
                        }
                    }
                } header: {
                    Label("All Devices", symbol: .antennaRadiowavesLeftAndRight)
                }

                Section {
                    Toggle("Fitness machines only", symbol: .sliderHorizontal3, isOn: Binding(
                        get: { viewModel.explorer.scansFitnessMachinesOnly },
                        set: { viewModel.explorer.scansFitnessMachinesOnly = $0 }
                    ))
                } footer: {
                    Text("Some machines omit their service UUIDs from the advertising packet and only reveal them once connected. Leave this off if the machine you expect is missing.")
                }
            }
            .navigationTitle("TestDrive")
            .searchable(text: $viewModel.searchText, prompt: "Filter by name")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isScanning ? "Stop" : "Scan", symbol: viewModel.isScanning ? .stopCircleFill : .magnifyingglass) {
                        viewModel.toggleScan()
                    }
                    .disabled(!viewModel.isBluetoothReady)
                }

                ToolbarItem(placement: .status) {
                    if viewModel.isScanning {
                        Text("^[\(viewModel.discoveredCount) device](inflect: true) found")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                viewModel.startScanIfPossible()
            }
        }
    }

    // MARK: - Private Views

    /// A navigation row for one discovered peripheral.
    private func peripheralLink(_ peripheral: DiscoveredPeripheral) -> some View {
        NavigationLink {
            PeripheralDetailView(
                viewModel: PeripheralDetailViewModel(
                    explorer: viewModel.explorer,
                    peripheral: peripheral
                )
            )
        } label: {
            peripheralRow(peripheral)
        }
    }

    /// The contents of a peripheral row: name, subtitle, and signal strength.
    private func peripheralRow(_ peripheral: DiscoveredPeripheral) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(peripheral.displayName)
                    .font(.body)

                Text(viewModel.subtitle(for: peripheral))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(peripheral.signalStrength) dBm")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(signalColor(for: peripheral.signalStrength))

                Text("^[\(peripheral.advertisementCount) packet](inflect: true)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// The banner shown when the Bluetooth stack is not ready.
    private func unavailableSection(message: String) -> some View {
        Section {
            Label(message, symbol: .exclamationmarkTriangle)
                .foregroundStyle(.orange)
        }
    }

    // MARK: - Private Helpers

    /// Colours an RSSI reading by rough usefulness.
    /// - Parameter signalStrength: The RSSI in dBm.
    /// - Returns: Green for a strong signal, orange for usable, red for marginal.
    private func signalColor(for signalStrength: Int) -> Color {
        switch signalStrength {
        case (-60)...: .green
        case (-80)..<(-60): .orange
        default: .red
        }
    }
}

#Preview {
    ScannerView()
}
