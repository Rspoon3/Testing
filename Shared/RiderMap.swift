//
//  RiderMap.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/3/21.
//

import SwiftUI
import MapKit

struct RiderMap: UIViewRepresentable {
    private let mapView = MKMapView()
    let nashua = CLLocationCoordinate2D(latitude: 42.74658038844741, longitude: -71.50032246048838)
    let span    = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    @State private var endAnnotation: AnimatableAnnotation? = nil
    @State private var overlay: MKOverlay? = nil
    
    @Binding var distanceRemaining: String
    @Binding var timeRemaining: String
    @Binding var followCamera: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let lowell = CLLocationCoordinate2D(latitude: 42.601619944327965, longitude: -71.33422851562501)
        
        createPath(from: nashua, to: lowell)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    
    private func createPath(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D){
        let sourcePlacemark = MKPlacemark(coordinate: start)
        let source = MKMapItem(placemark: sourcePlacemark)
        let destinationPlacemark = MKPlacemark(coordinate: end)
        let destination = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile
        
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else { return }
            let center = CLLocationCoordinate2D(latitude: end.latitude, longitude: end.longitude)
            let region = MKCoordinateRegion(center: center, span: span)
            
            let measurement = Measurement(value: route.distance, unit: UnitLength.meters)
            let formatter = MeasurementFormatter()
            formatter.locale = .current
            formatter.unitStyle = .long
            formatter.numberFormatter.maximumFractionDigits = 2
            
            let dateCF = DateComponentsFormatter()
            dateCF.unitsStyle = .full
            dateCF.allowedUnits = [.hour, .minute, .second]
            
            let components = DateComponents(second: Int(route.expectedTravelTime))
            
            distanceRemaining = formatter.string(from: measurement)
            timeRemaining = dateCF.string(from: components) ?? "N/A"
            
            if let endAnnotation = endAnnotation {
                let duration = 1.0
                UIView.animate(withDuration: duration) {
                    endAnnotation.coordinate = end
                }
                
                if followCamera{
                    mapView.animatedZoom(zoomRegion: region, duration: duration)
                }
                
                mapView.removeOverlay(overlay!)
                overlay = route.polyline
                mapView.addOverlay(overlay!)
            } else {
                endAnnotation = AnimatableAnnotation(coordinate: end)
                mapView.addAnnotations([sourcePlacemark, endAnnotation!])
                mapView.setRegion(region, animated: true)
                
                overlay = route.polyline
                mapView.addOverlay(overlay!)
            }
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        private var parent: RiderMap
        
        init(_ parent: RiderMap) {
            self.parent = parent
            super.init()
            SocketIOManager.shared.getLocation { location in
                guard let location = location else { return }
                let updatedLocation = CLLocationCoordinate2D(latitude: location.lat, longitude: location.long)
                parent.createPath(from: parent.nashua, to: updatedLocation)
                print("Changing to \(updatedLocation)")
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
    }
}


struct RiderMap_Previews: PreviewProvider {
    static var previews: some View {
        RiderMap(distanceRemaining: .constant(""), timeRemaining: .constant(""), followCamera: .constant(true))
    }
}
