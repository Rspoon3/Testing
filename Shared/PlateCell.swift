//
//  PlateCell.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI

struct PlateCell: View {
    let state: USState
    @Namespace private var animation

    var body: some View {
        NavigationLink {
            PlatesDetailsView(state: state)
                .backDeployedZoomNavigationTransition(
                    sourceID: state.id,
                    in: animation
                )
        } label: {
            mainContent
        }
        .buttonStyle(.plain)
    }
    
    private var mainContent: some View {
        VStack {
            Image("texasPlate")
                .resizable()
                .scaledToFit()
            
            Text(state.title)
                .font(.headline)
            Text(state.tagline)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.lightText))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .backDeployedMatchedTransitionSource(
            id: state.id,
            in: animation
        )
        .contextMenu {
            Button("Collect", symbol: .star) {
                
            }
        }
    }
}

#Preview {
    PlateCell(state: .newHampshire)
}
