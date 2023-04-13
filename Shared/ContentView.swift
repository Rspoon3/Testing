//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: DiscoverTab = .offers
    @Namespace private var tabIndicatorAnimation
    @State private var width: CGFloat = 64
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(DiscoverTab.allCases) { tab in
                VStack(spacing: 10) {
                    Image(systemName: tab.assetTitle(isSelected: selectedTab == tab))
                        .resizable()
                        .frame(width: 24, height: 24)
                        .onTapGesture {
                            withAnimation(.linear(duration: 0.1)) {
                                selectedTab = tab
                            }
                        }

                    if selectedTab == tab {
                        Capsule()
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "TabIndicator", in: tabIndicatorAnimation)
                            .foregroundColor(Color.blue)
                    }
                }
                .frame(width: width)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
