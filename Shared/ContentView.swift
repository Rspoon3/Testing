//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    let start = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
    let destination = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    let altimeterManager = AltimeterManager()
    @State private var altitude = 0.0

    var body: some View {
        let result = AntennaDirectionCalculator.calculateDirection(from: start, to: destination)
        
        VStack {
            Text("Distance: \(result.distance) km")
            Text("Bearing: \(result.bearing)°")
            Text("altitude: \(altitude)°")
            Text("Compass Direction: \(result.compassDirection)")
        }
        .onAppear {
            altimeterManager.fetchCurrentAltitude {  altitude in
                self.altitude = altitude ?? 0
            }
        }
    }
}


#Preview {
    ContentView()
}
