//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import CoreLocation
import MapKit

import SwiftUI
import UIKit

struct SearchBarView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
            searchBar.showsCancelButton = !searchText.isEmpty // Show cancel button when typing
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder() // Dismiss keyboard on search
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            text = ""
            searchBar.text = ""
            searchBar.showsCancelButton = false
            searchBar.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.autocapitalizationType = .none
        searchBar.showsCancelButton = false
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)

        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

struct MapSheetOverlay: View {
    @State var searchText: String = ""
    
    var body: some View {
        VStack {
            SearchBarView(text: $searchText, placeholder: "Search")
                .offset(x:0, y: -10)
            Text("Here")
        }
//        NavigationStack {
//            Text("MapSheetOverlay")
//                .searchable(text: $searchText)
//                .navigationBarTitleDisplayMode(.inline)
//                .navigationBarTitle("")
//                .searchPresentationToolbarBehavior(.avoidHidingContent)
//        }
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default: San Francisco
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    @State private var altitude: Double = 0.0
    @State private var distance: Double = 0.0
    @State private var bearing: Double = 0.0
    @State private var compassDirection: String = ""
    @State private var showContactPicker = false
    @State private var selectedAddress: String = ""
    @State private var showSheet = true

    let altimeterManager = AltimeterManager()
    
    var body: some View {
        MapView(
            startCoordinate: $startCoordinate,
            destinationCoordinate: $destinationCoordinate,
            region: $region
        )
        .ignoresSafeArea()
        .sheet(isPresented: $showSheet) {
            MapSheetOverlay()
                .interactiveDismissDisabled()
                .presentationDetents(
                    [
                        .fraction(0.15),
                        .fraction(0.45),
                        .fraction(0.96)
                    ]
                )
                .presentationBackgroundInteraction(.enabled)
        }
    }
    
    var bodyd: some View {
        ScrollView {
            // Map View
            MapView(startCoordinate: $startCoordinate, destinationCoordinate: $destinationCoordinate, region: $region)
                .frame(height: 400)
                .cornerRadius(15)
                .padding()
            
            VStack {
                Text("Selected Address:")
                    .font(.headline)
                
                Text(selectedAddress.isEmpty ? "No address selected" : selectedAddress)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button("Select Contact Address") {
                    showContactPicker = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(selectedAddress: $selectedAddress, onAddressSelected: { address in
                    self.selectedAddress = address
                    geocodeAddress(address)
                })
            }
            
            // Location Input Buttons
            HStack {
                Button(action: {
                    locationManager.fetchCurrentLocation { location in
                        self.startCoordinate = location
                        updateCalculations()
                    }
                }) {
                    Label("Use Current Location", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                SearchView { coordinate in
                    self.destinationCoordinate = coordinate
                    updateCalculations()
                }
            }
            .padding()

            // Information Display
            VStack(spacing: 8) {
                Text("Distance: \(String(format: "%.2f", distance)) km")
                Text("Bearing: \(String(format: "%.2f", bearing))° (\(compassDirection))")
                Text("Altitude: \(String(format: "%.2f", altitude)) m")
            }
            .font(.title3)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
            .padding()

            Spacer()
        }
        .onAppear {
            locationManager.fetchCurrentLocation { location in
                self.startCoordinate = location
            }
        }
    }

    /// Converts an address to coordinates and updates the destination location
    private func geocodeAddress(_ address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let location = placemarks?.first?.location else {
                print("Geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.destinationCoordinate = location.coordinate
            updateCalculations()
        }
    }

    private func updateCalculations() {
        guard let start = startCoordinate, let destination = destinationCoordinate else { return }
        let result = AntennaDirectionCalculator.calculateDirection(from: start, to: destination)
        self.distance = result.distance
        self.bearing = result.bearing
        self.compassDirection = result.compassDirection
        
        altimeterManager.fetchCurrentAltitude { altitude in
            self.altitude = altitude ?? 0
        }
    }
}

#Preview {
    ContentView()
}
