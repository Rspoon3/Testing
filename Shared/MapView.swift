//
//  MapView.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    @Namespace var mapScope
    let states = Bundle.main.decode(
        [USState].self,
        from: "states.json"
    )
    
    var body: some View {
        Map(scope: mapScope) {
            // Add annotations for each state capital
            ForEach(states) { state in
                Annotation(
                    state.capital,
                    coordinate: .init(
                        latitude: state.latitude,
                        longitude: state.longitude
                    )
                ) {
                    Image(symbol: .sparkles)
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
        .mapControls {
            MapUserLocationButton(scope: mapScope)
        }
    }
}

#Preview {
    MapView()
}
