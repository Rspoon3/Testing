//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    private let size: CGFloat = 20
    private let circleHStackSpacing: CGFloat = 6
    private let mainHStackSpacing: CGFloat = 10
    private let strokeLineWidth: CGFloat = 3
    private let xOffset: CGFloat = 14
    @State private var likeCount = 2
    @State private var showMyAvatar = false
    
    var myAvatarXOffset: CGFloat {
        showMyAvatar ? xOffset + mainHStackSpacing + circleHStackSpacing : 0
    }
    
    func startTimer() {
        let _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            showMyAvatar.toggle()
            likeCount = showMyAvatar ? 3 : 2
        }
    }
    
    var body: some View {
        HStack(spacing: mainHStackSpacing) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: strokeLineWidth)
                    .fill(.blue)
                    .frame(width: size, height: size)
                    .offset(x: myAvatarXOffset)
                    .opacity(showMyAvatar ? 1 : 0)
                    .scaleEffect(showMyAvatar ? 1 : 0)

                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(.pink)
                    .symbolEffect(.bounce, value: showMyAvatar)
            }
            .zIndex(1.0)
            .onTapGesture {
                showMyAvatar.toggle()
                likeCount = showMyAvatar ? 3 : 2
            }
            
            HStack(spacing: 4) {
                HStack(spacing: -circleHStackSpacing) {
                    Circle()
                        .stroke(.white, lineWidth: strokeLineWidth)
                        .fill(.green)
                        .frame(width: size, height: size)
                        .zIndex(2.0)
                        .offset(x: showMyAvatar ? xOffset : 0)
                    
                    Circle()
                        .foregroundStyle(.red)
                        .frame(width: size, height: size)
                        .zIndex(1.0)
                }
                
                Text(likeCount.formatted(.number.notation(.compactName)))
                    .contentTransition(.numericText())
            }
        }
        .animation(.easeInOut, value: showMyAvatar)
        .padding()
        .onAppear {
            startTimer()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
