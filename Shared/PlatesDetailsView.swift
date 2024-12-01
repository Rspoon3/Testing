//
//  PlatesDetailsView.swift
//  Testing (iOS)
//
//  Created by Ricky on 11/30/24.
//

import SwiftUI
import MapKit

struct PlatesDetailsView: View {
    let state: USState
    private let region = MKCoordinateRegion(
         center: CLLocationCoordinate2D(latitude: 43.2081, longitude: -71.5376),
         span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
     )

    var body: some View {
        ScrollView {
            Image("texasPlate")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .padding(.bottom, 50)
            
            VStack(spacing: 20) {
                LabeledContent("State Moto", value: state.motto)
                LabeledContent("State Tagline", value: state.tagline)
                LabeledContent("Population", value: state.estimatedPopulation.formatted())
                LabeledContent("Founded", value: state.yearFounded.formatted())
                LabeledContent("State Number", value: state.stateNumber.formatted())
                LabeledContent("Capital", value: state.capital)
                
                Text(state.funDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.regular)
                Text(state.neatFact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.regular)
            }
            .font(.title2)
            .fontWeight(.semibold)
            
            Map {
                Annotation(
                    "Diller Civic Center Playground",
                    coordinate: region.center
                ) {
                    VStack {
                        Image(symbol: .starFill)
                            .foregroundStyle(.yellow)
                        Text(state.capital)
                            .padding(5)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding(.top, 50)
            .mapControlVisibility(.hidden)
        }
        .contentMargins(10, for: .scrollContent)
        .multilineTextAlignment(.leading)
        .frame(maxHeight: .infinity)
        .navigationTitle(state.title)
        .background {
            Image("goldenGate")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 20)
                .overlay(Color.white.opacity(0.4))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(symbol: .star) {
                    
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        PlatesDetailsView(state: .newHampshire)
    }
}
