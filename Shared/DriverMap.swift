//
//  DriverMap.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/3/21.
//

import SwiftUI
import MapKit

struct DriverMap: UIViewRepresentable {
    private let mapView = MKMapView()
    private let span    = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    let duration = 1.0
    @State private var endAnnotation: AnimatableAnnotation? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let lowell = CLLocationCoordinate2D(latitude: 42.601619944327965, longitude: -71.33422851562501)
        let center = CLLocationCoordinate2D(latitude: lowell.latitude, longitude: lowell.longitude)
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: true)
        return mapView
    }
    
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
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
    
    class Coordinator: NSObject, MKMapViewDelegate {
        private var parent: DriverMap
        var lat = 42.601619944327965
        
        init(_ parent: DriverMap) {
            self.parent = parent
            super.init()
            
            _ = Timer.scheduledTimer(withTimeInterval: parent.duration, repeats: true) { timer in
                self.lat += 0.002
                let long = -71.33422851562501
                let updatedLocation = CLLocationCoordinate2D(latitude: self.lat, longitude: long)
                parent.updateLocation(updatedLocation)
                SocketIOManager.shared.sendLocation(lat: self.lat, long: long)
//                print("Changing to \(updatedLocation)")
            }
        }
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            return nil
        }
    }
}


struct DriverMap_Previews: PreviewProvider {
    static var previews: some View {
        DriverMap()
    }
}
