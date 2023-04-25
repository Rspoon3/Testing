//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State var currentTab: Int = 0
    @Namespace var namespace

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: self.$currentTab) {
                view1.tag(0)
                view2.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .edgesIgnoringSafeArea(.all)
            
            navigationBarView
        }
    }
    
    
    var navigationBarView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                navBarItem(string: "Offers", tab: 1)
                navBarItem(string: "Brands", tab: 2)
            }
            .padding(.horizontal)
        }
        .background(Color.white)
        .frame(height: 80)
        .edgesIgnoringSafeArea(.top)
    }
    
    
    func navBarItem(string: String, tab: Int) -> some View {
        Button {
            self.currentTab = tab
        } label: {
            VStack {
                Spacer()
                Text(string)
                    .font(.system(size: 13, weight: .light, design: .default))
                if self.currentTab == tab {
                    Color.black.frame(height: 2)
                        .matchedGeometryEffect(id: "underline", in: namespace, properties: .frame)
                } else {
                    Color.clear.frame(height: 2)
                }
            }
            .animation(
//                .spring(
//                    response: 0.155,
//                    dampingFraction: 1.825,
//                    blendDuration: 0
//                ),
//                .interpolatingSpring(stiffness: 1000, damping: 40, initialVelocity: 10),
                .interpolatingSpring(stiffness: 1000, damping: 35),
                value: currentTab
            )
        }
        .buttonStyle(.plain)
    }
    
    var view1: some View {
        Color.red.opacity(0.2).edgesIgnoringSafeArea(.all)
    }
    
    var view2: some View {
        Color.blue.opacity(0.2).edgesIgnoringSafeArea(.all)
    }
    
    var view3: some View {
        Color.yellow.opacity(0.2).edgesIgnoringSafeArea(.all)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


