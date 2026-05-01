//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    let player = MusicPlayer()
    
    var body: some View {
        VStack(spacing: 50) {
            Button("Start") {
                Task {
                    await player.start()
                }
            }
            
            Button("New Song") {
                player.newSong()
            }
        }
        .font(.largeTitle)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

