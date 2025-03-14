//
//  MapView.swift
//  Testing
//
//  Created by Ricky on 3/13/25.
//


import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var destinationCoordinate: CLLocationCoordinate2D?
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)

        if let start = startCoordinate {
            let startPin = MKPointAnnotation()
            startPin.coordinate = start
            startPin.title = "Location A"
            uiView.addAnnotation(startPin)
        }

        if let destination = destinationCoordinate {
            let destinationPin = MKPointAnnotation()
            destinationPin.coordinate = destination
            destinationPin.title = "Location B"
            uiView.addAnnotation(destinationPin)
        }

        if let start = startCoordinate, let destination = destinationCoordinate {
            let line = MKPolyline(coordinates: [start, destination], count: 2)
            uiView.addOverlay(line)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

            parent.destinationCoordinate = coordinate
        }
    }
}