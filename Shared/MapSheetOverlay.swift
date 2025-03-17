//
//  MapSheetOverlay.swift
//  Testing
//
//  Created by Ricky on 3/16/25.
//

import SwiftUI

struct MapSheetOverlay: View {
    @ObservedObject var viewModel: MapSheetOverlayViewModel

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.searchText.isEmpty {
                    Section {
                        LabeledContent("From", value: viewModel.startAddress)
                        LabeledContent("To", value: viewModel.destinationAddress)
                    } header: {
                        HStack {
                            Text("Locations")
                            Spacer()
                            Button {
                                viewModel.swapSourceAndDestination()
                            } label: {
                                Image(systemName: "arrow.trianglehead.counterclockwise")
                            }
                        }
                    }
                    
                    Section("Results") {
                        LabeledContent("Your Altitude", value: viewModel.altitude.formatted())
                        LabeledContent("Bearing", value: viewModel.bearing.formatted())
                        LabeledContent("Distance", value: viewModel.distance.formatted())
                    }
                    
                    Section("Recents") {
                        
                    }
                } else {
                    List(viewModel.results, id: \.self) { item in
                        Button {
                            viewModel.didSelect(item)
                        } label: {
                            Text(item.placemark.name ?? "Unknown Location")
                        }
                    }
                    .overlay {
                        if viewModel.isLoadingPlacemarks {
                            ProgressView()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .searchable(text: $viewModel.searchText, isPresented: $viewModel.searchIsActive)
            .onAppear(perform: viewModel.fetchLocation)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showContactPicker.toggle()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showContactPicker) {
                ContactPickerView(selectedAddress: $viewModel.selectedAddress){ address in
                    viewModel.selectedAddress = address

                    Task {
                        try await viewModel.geocodeAddress(address)
                    }
                }
            }
        }
    }
}

#Preview {
    MapSheetOverlay(viewModel: .init())
}
