//
//  HomeView.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

import SwiftUI

struct HomeView: View {
    @State private var show = false
    @Namespace private var animation

    var body: some View {
        VStack {
            MemoryColorsTitleView()
            
            Spacer()
            
            
            Button {

            } label:{
                Text("Leaderboard")
                    .font(.largeTitle)
                    .frame(maxWidth: 300)
            }
            .buttonStyle(.plain)
            .padding(.vertical)
            .background {
                Capsule()
                    .foregroundStyle(.white)
            }
            
            Button {

            } label:{
                Text("Settings")
                    .font(.largeTitle)
                    .frame(maxWidth: 300)
            }
            .buttonStyle(.plain)
            .padding(.vertical)
            .background {
                Capsule()
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                show = true
            } label: {
                VStack {
                    Text("Play!")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        
                    Text("High Score: Round 8")
                        .padding()
                        .background(Color.blue)
                        .font(.headline)
                        .cornerRadius(8)
                }
                .foregroundStyle(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
            .padding(.bottom, 50)
            .backDeployedMatchedTransitionSource(
                id: "play",
                in: animation
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fullScreenCover(isPresented: $show) {
            GameView()
                .backDeployedZoomNavigationTransition(
                    sourceID: "play",
                    in: animation
                )
        }
        .background(
            Image("wallpaper")
                .resizable()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.3))
        )
    }
}

#Preview {
    HomeView()
}


struct MemoryColorsTitleView: View {
    var body: some View {
        VStack(spacing: 8) {  // Vertical spacing between the two words
            HStack(spacing: 2) {
                ForEach("MEORY".map { String($0) }, id: \.self) { letter in
                    Text(letter)
                        .font(.title)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 2) {
                ForEach("PICTURES".map { String($0) }, id: \.self) { letter in
                    Text(letter)
                        .font(.title)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
    }
}



public extension View {
    /// A back deployed version of `matchedTransitionSource`.
    @available(iOS, deprecated: 18, obsoleted: 18, message: "This extension can be removed once iOS 18 is the minimum deployment target.")
    nonisolated func backDeployedMatchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            return self
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            return self
        }
    }
    
    /// A back deployed version of `navigationTransition`.
    @available(iOS, deprecated: 18, obsoleted: 18, message: "This extension can be removed once iOS 18 is the minimum deployment target.")
    nonisolated func backDeployedZoomNavigationTransition(sourceID: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            return self
                .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            return self
        }
    }
}
