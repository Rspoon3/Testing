//
//  SearchView.swift
//  Testing
//
//  Created by Ricky on 3/13/25.
//


import SwiftUI
import MapKit

struct SearchView: View {
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    var onSelect: (CLLocationCoordinate2D) -> Void

    var body: some View {
        VStack {
            TextField("Search for a place...", text: $query, onCommit: performSearch)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            List(results, id: \.self) { item in
                Button(action: {
                    onSelect(item.placemark.coordinate)
                    query = ""
                    results.removeAll()
                }) {
                    Text(item.placemark.name ?? "Unknown Location")
                }
            }
        }
    }

    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            if let response = response {
                self.results = response.mapItems
            }
        }
    }
}