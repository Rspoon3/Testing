//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = MapSheetOverlayViewModel()

    var body: some View {
        MapView(
            startCoordinate: $viewModel.startCoordinate,
            destinationCoordinate: $viewModel.destinationCoordinate,
            region: $viewModel.region
        )
        .ignoresSafeArea()
        .sheet(isPresented: $viewModel.showOverlaySheet) {
            MapSheetOverlay(viewModel: viewModel)
                .interactiveDismissDisabled()
                .presentationBackgroundInteraction(.enabled)
                .presentationDetents(
                    [
                        .fraction(0.15),
                        .fraction(0.45),
                        .fraction(0.96)
                    ],
                    selection: $viewModel.presentationDetent
                )
        }
    }
}

#Preview {
    ContentView()
}
