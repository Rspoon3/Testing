//
//  DriverMap.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/3/21.
//

import SwiftUI
import MapKit
import CoreLocation


struct DriverMap: UIViewRepresentable {
    private let mapView = MKMapView()
    private let span    = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    private let duration = 1.0
    private let locationManager = CLLocationManager()
    
    @State private var endAnnotation: AnimatableAnnotation? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let lowell = CLLocationCoordinate2D(latitude: 42.601619944327965, longitude: -71.33422851562501)
        let center = CLLocationCoordinate2D(latitude: lowell.latitude, longitude: lowell.longitude)
        let region = MKCoordinateRegion(center: center, span: span)
        
        configureLocationManager(context: context)
        
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: true)
        return mapView
    }
    
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    
    //MARK: - Helpers
    private func configureLocationManager(context: Context){
        locationManager.delegate = context.coordinator
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 5//meters
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.requestLocation()
    }
    
    
    private func updateLocation(_ location : CLLocationCoordinate2D){
        
        if let endAnnotation = endAnnotation {
            UIView.animate(withDuration: duration) {
                endAnnotation.coordinate = location
            }
            
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.animatedZoom(zoomRegion: region, duration: duration)
        } else {
            endAnnotation = AnimatableAnnotation(coordinate: location)
            mapView.addAnnotations([endAnnotation!])
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private var parent: DriverMap
        
        init(_ parent: DriverMap) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            return nil
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let currentLocation = locations.first else { return }
            let lat  = currentLocation.coordinate.latitude
            let long = currentLocation.coordinate.longitude
            let updatedLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
            parent.updateLocation(updatedLocation)
            SocketIOManager.shared.sendLocation(lat: lat, long: long)
            
            print("Changing location")
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Error: \(error)")
        }
    }
}


struct DriverMap_Previews: PreviewProvider {
    static var previews: some View {
        DriverMap()
    }
}
