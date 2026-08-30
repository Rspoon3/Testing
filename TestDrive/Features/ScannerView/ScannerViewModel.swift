//
//  ScannerViewModel.swift
//  TestDrive
//

import Observation
import Foundation
import CoreBluetooth

/// Drives ``ScannerView``: owns the Bluetooth explorer and shapes the discovered
/// peripherals into the sections the list renders.
@Observable
final class ScannerViewModel {

    /// The Bluetooth explorer shared with the detail screen.
    let explorer: BluetoothExplorer

    /// Free-text filter applied to peripheral names.
    var searchText = ""

    /// Whether the Bluetooth stack is ready to scan.
    var isBluetoothReady: Bool { explorer.managerState == .poweredOn }

    /// A message to show when Bluetooth is unavailable, or `nil` when it is ready.
    var unavailableMessage: String? {
        isBluetoothReady ? nil : explorer.managerState.label
    }

    /// Whether a scan is running.
    var isScanning: Bool { explorer.isScanning }

    /// Peripherals that advertise the Fitness Machine Service, strongest signal first.
    var fitnessMachines: [DiscoveredPeripheral] {
        filtered.filter(\.isFitnessMachine).sorted { $0.signalStrength > $1.signalStrength }
    }

    /// Every other peripheral, strongest signal first.
    var otherPeripherals: [DiscoveredPeripheral] {
        filtered.filter { !$0.isFitnessMachine }.sorted { $0.signalStrength > $1.signalStrength }
    }

    /// The total number of peripherals seen in this scan.
    var discoveredCount: Int { explorer.discoveredPeripherals.count }

    // MARK: - Initializer

    /// Creates a view model.
    /// - Parameter explorer: The explorer to scan with. Defaults to a new instance.
    init(explorer: BluetoothExplorer = BluetoothExplorer()) {
        self.explorer = explorer
    }

    // MARK: - Public Helpers

    /// Starts or stops the scan depending on the current state.
    func toggleScan() {
        if explorer.isScanning {
            explorer.stopScan()
        } else {
            explorer.startScan()
        }
    }

    /// Requests a scan when the screen appears.
    ///
    /// Safe to call before Bluetooth is ready: the explorer holds the request and
    /// replays it once the stack powers on, which is what happens on a first launch
    /// while the permission prompt is still on screen.
    func startScanIfPossible() {
        guard !explorer.isScanning else { return }
        explorer.startScan()
    }

    /// A one-line summary of a peripheral for the list row.
    /// - Parameter peripheral: The peripheral to describe.
    /// - Returns: The declared machine types when known, otherwise a service count.
    func subtitle(for peripheral: DiscoveredPeripheral) -> String {
        let declaredTypes = peripheral.advertisement.declaredFitnessMachineTypes
        if !declaredTypes.isEmpty {
            return declaredTypes.joined(separator: ", ")
        }

        let serviceCount = peripheral.advertisement.serviceUUIDs.count
        if serviceCount > 0 {
            return "\(serviceCount) advertised service\(serviceCount == 1 ? "" : "s")"
        }

        return peripheral.advertisement.manufacturerData == nil
            ? "No advertised services"
            : "Manufacturer data only"
    }

    // MARK: - Private Helpers

    /// The discovered peripherals matching ``searchText``.
    private var filtered: [DiscoveredPeripheral] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return explorer.discoveredPeripherals }
        return explorer.discoveredPeripherals.filter {
            $0.displayName.localizedCaseInsensitiveContains(query)
        }
    }
}
