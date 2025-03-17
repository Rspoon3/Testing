//
//  MapSheetOverlayViewModel.swift
//  Testing
//
//  Created by Ricky on 3/16/25.
//

import CoreLocation
import MapKit
import Combine
import SwiftUI

@MainActor
final class MapSheetOverlayViewModel: ObservableObject {
    @Published var showOverlaySheet = true
    @Published var showContactPicker = false
    @Published var results: [MKMapItem] = []
    @Published var searchText: String = ""
    @Published var presentationDetent: PresentationDetent = .fraction(0.45)
    @Published var isLoadingPlacemarks = false
    @Published var searchIsActive = false {
        willSet {
            if searchIsActive {
                presentationDetent = .fraction(0.96)
            } else {
                presentationDetent = .fraction(0.15)
            }
        }
    }
    
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default: San Francisco
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    @Published var altitude: Double = 0.0
    @Published var distance: Double = 0.0
    @Published var bearing: Double = 0.0
    @Published var compassDirection: String = ""
    @Published var selectedAddress: String = ""
    @Published var startCoordinate: CLLocationCoordinate2D?
    
    @Published var startAddress: String = ""
    @Published var destinationAddress: String = ""

    
    private var cancellables = Set<AnyCancellable>()
    private let geocoder = CLGeocoder()
    private let altimeterManager = AltimeterManager()
    private let locationManager = LocationManager()
    
    // MARK: - Initializer
    
    init() {
        $searchText
            .debounce(
                for: .milliseconds(300),
                scheduler: DispatchQueue.main
            )
            .sink { [weak self] value in
                Task {
                    self?.isLoadingPlacemarks = true
                    await self?.performSearch(text: value)
                    self?.isLoadingPlacemarks = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func didSelect(_ item: MKMapItem) {
        withAnimation {
            searchText = ""
            searchIsActive = false
            results.removeAll()
            
            destinationCoordinate = item.placemark.coordinate
            updateCalculations()
            
            presentationDetent = .fraction(0.45)
        }
    }
    
    func fetchLocation() {
        locationManager.fetchCurrentLocation { location in
            DispatchQueue.main.async {
                self.startCoordinate = location
            }
        }
    }
    
    func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        print("Getting location ", location)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first {
                let address = [
                    placemark.name,            // Street name or building name
                    placemark.locality,        // City
                    placemark.administrativeArea, // State or province
                    placemark.country          // Country
                ].compactMap { $0 }.joined(separator: ", ") // Format the address
                
                print("Got address", address)
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Converts an address to coordinates and updates the destination location
    func geocodeAddress(_ address: String) async throws {
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let location = placemarks.first?.location else { return }
        destinationCoordinate = location.coordinate
        updateCalculations()
    }
    
    func swapSourceAndDestination() {
        (startCoordinate, destinationCoordinate) = (destinationCoordinate, startCoordinate)
        updateCalculations()
    }
    
    // MARK: - Private
    
    private func performSearch(text: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        guard let response = try? await search.start() else { return }
        results = response.mapItems
    }
    
    private func updateCalculations() {
        guard let startCoordinate, let destinationCoordinate else { return }
        let result = AntennaDirectionCalculator.calculateDirection(from: startCoordinate, to: destinationCoordinate)
        self.distance = result.distance
        self.bearing = result.bearing
        self.compassDirection = result.compassDirection
        
        altimeterManager.fetchCurrentAltitude { altitude in
            DispatchQueue.main.async {
                self.altitude = altitude ?? 0
            }
        }
        
        reverseGeocodeLocation(startCoordinate) { [weak self] startValue in
            guard let startValue, let self else { return }
            
            reverseGeocodeLocation(destinationCoordinate) { destinationValue in
                guard let destinationValue else { return }
                
                DispatchQueue.main.async {
                    self.startAddress = startValue
                    self.destinationAddress = destinationValue
                }
            }
        }
    }
}
