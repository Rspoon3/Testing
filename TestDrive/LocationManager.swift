//
//  LocationManager.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/19/25.
//

import CoreLocation

final class LocationManager: NSObject {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    enum LocationError: Error {
        case permissionDenied
        case unableToFindLocation
    }
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy =  kCLLocationAccuracyThreeKilometers
    }
    
    // MARK: - Public
    
    @discardableResult
    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        let status = locationManager.authorizationStatus
        print("Requesting")
        
        // If already determined, return immediately
        if status != .notDetermined {
            print("already determined")
            return status
        }
        
        return await withCheckedContinuation { continuation in
            self.authContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func currentLocation() async throws -> CLLocationCoordinate2D {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                locationManager.requestLocation()
            }
        default:
            throw LocationError.permissionDenied
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else {
            locationContinuation?.resume(throwing: LocationError.unableToFindLocation)
            locationContinuation = nil
            return
        }

        locationContinuation?.resume(returning: coordinate)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("locationManagerDidChangeAuthorization \(status)")

        // Wait until user has made a decision
        guard status != .notDetermined else { return }

        if let continuation = authContinuation {
            continuation.resume(returning: status)
            authContinuation = nil
        }

        // Handle denied case for location requests
        if status == .denied || status == .restricted {
            locationContinuation?.resume(throwing: LocationError.permissionDenied)
            locationContinuation = nil
        }
    }
}
