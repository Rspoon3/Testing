//
//  GameOverView.swift
//  Testing
//
//  Created by Ricky on 11/3/24.
//

import SwiftUI

struct GameOverView: View {
    let play: ()->Void
    let end: ()->Void
    
    var body: some View {
        VStack {
            Text("Game Over!")
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Image(systemName: "trophy.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.yellow)
            
            HStack {
                Button {
                    end()
                } label :{
                    Image(systemName: "xmark")
                }
                .padding()
                .background {
                    Circle()
                        .foregroundStyle(.orange.gradient)
                }
                
                Spacer()
                
                Button {
                    play()
                } label :{
                    Image(systemName: "play.fill")
                }
                .padding()
                .background {
                    Circle()
                        .foregroundStyle(.orange.gradient)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .font(.largeTitle)
        .padding()
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.75)
        GameOverView {
            
        } end: {}
    }
}
