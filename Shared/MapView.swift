//
//  MapView.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI
import MapKit

import SwiftUI
import MapKit

struct MapView: View {
    // Define regions for 5 random state capitals
    let stateCapitals = [
        (name: "Montgomery, AL", coordinate: CLLocationCoordinate2D(latitude: 32.3792, longitude: -86.3077)),
        (name: "Juneau, AK", coordinate: CLLocationCoordinate2D(latitude: 58.3019, longitude: -134.4197)),
        (name: "Phoenix, AZ", coordinate: CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740)),
        (name: "Little Rock, AR", coordinate: CLLocationCoordinate2D(latitude: 34.7465, longitude: -92.2896)),
        (name: "Sacramento, CA", coordinate: CLLocationCoordinate2D(latitude: 38.5758, longitude: -121.4789))
    ]
    
    let region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129), // Center of the US
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50) // Broad view for multiple states
    )
    
    var body: some View {
        Map {
            // Add annotations for each state capital
            ForEach(stateCapitals, id: \.name) { capital in
                Annotation(capital.name, coordinate: capital.coordinate) {
                    Image(symbol: .licenseplate)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    MapView()
}
