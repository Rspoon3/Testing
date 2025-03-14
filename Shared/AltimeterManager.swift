//
//  AltimeterManager.swift
//  Testing
//
//  Created by Ricky on 3/13/25.
//

import CoreLocation

final class AltimeterManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var completion: ((Double?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func fetchCurrentAltitude(completion: @escaping (Double?) -> Void) {
        self.completion = completion
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        completion?(location.altitude) // Altitude in meters
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get altitude: \(error.localizedDescription)")
        completion?(nil)
    }
}
