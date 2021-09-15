//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//


import SwiftUI
import MapKit



struct DomainMap: UIViewRepresentable {
    let mapView = MKMapView()
    let cities: [City]

    //MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsCompass = false

        

        if cities.count != mapView.annotations.count{
            mapView.removeAnnotations(mapView.annotations)
            
            cities.forEach{
                let annotation = MKPointAnnotation()
                annotation.title = "London"
                annotation.coordinate = $0.coordinate
                mapView.addAnnotation(annotation)
            }
        }
        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        mapView.showsUserLocation = true


        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func calculateMapRect() -> MKMapRect{
        var points = cities.map(\.coordinate).map(MKMapPoint.init)
        
        points.append(MKMapPoint( mapView.userLocation.coordinate))
        
        var mapRect = points.reduce(MKMapRect.null){ rect, point in
            let newRect = MKMapRect (origin: point, size: MKMapSize())
            return rect.union(newRect)
        }
        
        let widthPadding: Double = mapRect.size.width * 0.1
        let heightPadding:Double = mapRect.size.height * 0.1

        mapRect.size = .init(width: mapRect.width + widthPadding, height: mapRect.height + heightPadding)
        mapRect.origin = .init(x: mapRect.origin.x - (widthPadding / 2), y: mapRect.origin.y - (heightPadding / 2))

        return mapRect
    }
    
    
    //MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private var parent: DomainMap
        
        init(_ parent: DomainMap) {
            self.parent = parent
            
            super.init()
            
            self.parent.mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if (annotation.isKind(of: MKUserLocation.self)){
                return nil
            }
           return MKMarkerAnnotationView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        DomainMap(cities: [.boston, .nyc])
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension CLLocationCoordinate2D : Equatable{
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public static let boston = CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589)
    public static let nyc = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    public static let nashua = CLLocationCoordinate2D(latitude: 42.746429087352105, longitude: -71.49995857870427)
    public static let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
    public static let cupertino = CLLocationCoordinate2D(latitude: 37.3230, longitude: -122.0322)
}


struct City: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    
    static let boston = City(coordinate: .boston)
    static let nyc    = City(coordinate: .nyc)
    static let nashua = City(coordinate: .nashua)
    static let cupertino = City(coordinate: .cupertino)
}
