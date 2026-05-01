//
//  MapSheetOverlay.swift
//  Testing
//
//  Created by Ricky on 3/16/25.
//

import SwiftUI

struct MapSheetOverlay: View {
    @ObservedObject var viewModel: MapSheetOverlayViewModel
    @State var show = false
    @State var selection: Selection = .start
    
    enum Selection {
        case start
        case destination
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        selection = .start
                        show.toggle()
                    } label: {
                        Label(
                            viewModel.startAddress,
                            systemImage: "antenna.radiowaves.left.and.right.circle"
                        )
                        .animation(.default, value: viewModel.startAddress)
                    }
                    
                    Button {
                        selection = .destination
                        show.toggle()
                    } label: {
                        Label(
                            viewModel.destinationAddress,
                            systemImage: "mappin.circle"
                        )
                        .animation(.default, value: viewModel.destinationAddress)
                    }
                    
                } header: {
                    HStack {
                        Text("Addresses")
                        Spacer()
                        Button("Swap") {
                            viewModel.swapSourceAndDestination()
                        }
                    }
                    .textCase(nil)
                }
                
                Section("Results") {
                    LabeledContent(
                        "Your Altitude",
                        value: Measurement(
                            value: viewModel.altitude,
                            unit: UnitLength.meters
                        )
                        .formatted()
                    )
                    
                    LabeledContent(
                        "Bearing",
                        value: Measurement(
                            value: viewModel.bearing,
                            unit: UnitAngle.degrees
                        )
                        .formatted(.measurement(width: .narrow, numberFormatStyle: .number.precision(.fractionLength(2))))
                    )
                    
                    LabeledContent(
                        "Distance",
                        value: Measurement(
                            value: viewModel.distance,
                            unit: UnitLength.kilometers
                        ).formatted()
                    )
                }
            }
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .onAppear(perform: viewModel.fetchLocation)
            .sheet(isPresented: $show) {
                MapItemSearchView(
                    searchQuery: $viewModel.searchText,
                    mapItems: viewModel.results,
                    viewModel: viewModel
                ) { item in
                    switch selection {
                    case .start:
                        viewModel.startCoordinate = item.placemark.coordinate
                    case .destination:
                        viewModel.destinationCoordinate = item.placemark.coordinate
                    }
                    
                    viewModel.updateCalculations()
                }
            }
        }
    }
}

#Preview {
    MapSheetOverlay(viewModel: .init())
}

import SwiftUI
import MapKit
import Combine
import Contacts
import CoreLocationUI

struct MapItemSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var searchQuery: String
    let mapItems: [MKMapItem]
    @State private var searchCancellable: AnyCancellable?
    @ObservedObject var viewModel: MapSheetOverlayViewModel
    let onSelect: (MKMapItem) -> Void

    var body: some View {
        NavigationView {
            List {
                Button {
                    viewModel.fetchLocation()
                    dismiss()
                } label: {
                    Label("Current Location", systemImage: "location")
                }
                
                Button {
                    viewModel.showContactPicker.toggle()
                } label: {
                    Label("Search Contacts", systemImage: "person.crop.circle")
                }
                
                ForEach(mapItems, id: \.self) { item in
                    Button {
                        onSelect(item)
                        dismiss()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Unknown")
                                    .font(.headline)
                                if let placemark = item.placemark.postalAddress {
                                    Text(formatPostalAddress(placemark))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(item.placemark.title ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "mappin.circle")
                        }
                    }
                }
            }
            .navigationTitle("Address Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search for address")
            .sheet(isPresented: $viewModel.showContactPicker) {
                ContactPickerView(selectedAddress: $viewModel.selectedAddress){ address in
                    viewModel.selectedAddress = address

                    Task {
                        defer { dismiss() }
                        try await viewModel.geocodeAddress(address)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showContactPicker.toggle()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
    }
    
    func formatPostalAddress(_ postalAddress: CNPostalAddress) -> String {
        CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
            .replacingOccurrences(of: "\n", with: ", ")
    }
}
