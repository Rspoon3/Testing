//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI
import CoreLocation

/// Main view for managing location-based notifications.
struct ContentView: View {
    @State private var locationManager = LocationManager()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusSection
                targetLocationSection
                actionButtons

                if let lastError = locationManager.lastError {
                    errorSection(lastError)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Location Alert")
        }
    }

    // MARK: - Private Views

    private var statusSection: some View {
        VStack(spacing: 12) {
            Text("Status")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("Location Permission:")
                Spacer()
                statusBadge(for: locationManager.authorizationStatus)
            }

            HStack {
                Text("Monitoring:")
                Spacer()
                Text(locationManager.isMonitoring ? "Active" : "Inactive")
                    .foregroundStyle(locationManager.isMonitoring ? .green : .secondary)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var targetLocationSection: some View {
        VStack(spacing: 12) {
            Text("Target Locations")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location 1:")
                        .fontWeight(.semibold)
                    Text("42.73732° N, 71.32320° W")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Location 2:")
                        .fontWeight(.semibold)
                    Text("42.67936° N, 71.34238° W")
                }

                Text("Radius: 100 meters")
                    .italic()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if locationManager.authorizationStatus == .notDetermined {
                Button {
                    locationManager.requestPermissions()
                } label: {
                    Text("Request Permissions")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if locationManager.authorizationStatus == .authorizedAlways {
                if !locationManager.isMonitoring {
                    Button {
                        locationManager.startMonitoring()
                    } label: {
                        Text("Start Monitoring")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        locationManager.stopMonitoring()
                    } label: {
                        Text("Stop Monitoring")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
    }

    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 8) {
            Text("Error")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Private Helpers

    /// Returns a status badge view for the given authorization status.
    /// - Parameter status: The current location authorization status.
    /// - Returns: A view displaying the status with appropriate styling.
    private func statusBadge(for status: CLAuthorizationStatus) -> some View {
        let (text, color) = statusText(for: status)
        return Text(text)
            .foregroundStyle(color)
            .fontWeight(.semibold)
    }

    /// Converts authorization status to display text and color.
    /// - Parameter status: The current location authorization status.
    /// - Returns: A tuple containing the status text and color.
    private func statusText(for status: CLAuthorizationStatus) -> (String, Color) {
        switch status {
        case .notDetermined:
            return ("Not Requested", .secondary)
        case .restricted:
            return ("Restricted", .orange)
        case .denied:
            return ("Denied", .red)
        case .authorizedAlways:
            return ("Authorized", .green)
        case .authorizedWhenInUse:
            return ("When In Use Only", .orange)
        @unknown default:
            return ("Unknown", .secondary)
        }
    }
}

#Preview {
    ContentView()
}
