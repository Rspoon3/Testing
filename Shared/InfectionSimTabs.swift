//
//  InfectionSimTabs.swift
//  Testing
//
//  Created by Ricky on 3/28/25.
//

import SwiftUI

struct InfectionSimTabs: View {
    var body: some View {
        TabView {
            BouncingBallsView()
                .tabItem {
                    Label("SwiftUI", systemImage: "rectangle.on.rectangle")
                }

            BouncingBallsView()
                .tabItem {
                    Label("SpriteKit", systemImage: "circle.grid.cross")
                }
        }
    }
}
