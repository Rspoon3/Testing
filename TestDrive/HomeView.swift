//
//  HomeView.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

import SwiftUI

struct HomeView: View {
    @State private var scale = false
    @State private var show = false
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 0) {
            MemoryColorsTitleView()
            
            Spacer()
            
            settingsButton
            leaderboardButton
                .padding(.top, 10)
            playButton
                .padding(.top, 75)
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
                .ignoresSafeArea(.all, edges: .vertical)
                .scaledToFill()
                .overlay(Color.black.opacity(0.3))
        )
    }
    
    private var playButton: some View {
        Button {
            show = true
        } label: {
            VStack {
                Text("Play!")
                    .scaleEffect(scale ? 1.04 : 1)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            scale.toggle()
                        }
                    }
                
                Text("High Score: Round 8")
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
            }
        }
        .buttonStyle(CapsuleButtonStyle(backgroundColor: .green))
    }
    
    private var settingsButton: some View {
        Button("Settings") {
            
        }
        .buttonStyle(CapsuleButtonStyle(backgroundColor: .blue))
    }
    
    private var leaderboardButton: some View {
        Button("Leaderboard") {
            
        }
        .buttonStyle(CapsuleButtonStyle(backgroundColor: .orange))
    }
}

#Preview {
    HomeView()
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
