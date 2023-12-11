//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    private let heartSize: CGFloat = 20
    private let circleSize: CGFloat = 18
    private let circleHStackSpacing: CGFloat = 6
    private let mainHStackSpacing: CGFloat = 10
    private let strokeLineWidth: CGFloat = 3
    private let xOffset: CGFloat = 14
    @State private var likeCount = 2
    @State private var showMyAvatar = false
    @State private var status: Status = .placeholder
    
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
        VStack(alignment: .leading, spacing: 30) {
            placeholder
            noLikes
            oneLike
            multipleLikes
            
            Button("Toggle") {
                showMyAvatar.toggle()
                likeCount = showMyAvatar ? 3 : 2
            }
            .font(.largeTitle)
        }
        .animation(.easeInOut, value: showMyAvatar)
        .padding()
    }
    
    var oneLike: some View {
        HStack(spacing: mainHStackSpacing) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: strokeLineWidth)
                    .fill(.blue)
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: myAvatarXOffset)
                    .opacity(showMyAvatar ? 1 : 0)
                    .scaleEffect(showMyAvatar ? 1 : 0)
                
                Image(systemName: showMyAvatar ? "heart.fill" : "heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: heartSize, height: heartSize)
                    .foregroundStyle(showMyAvatar ? Color.pink : .gray)
                    .symbolEffect(.bounce, value: showMyAvatar)
            }
            .zIndex(1.0)
            
            HStack(spacing: 4) {
                Circle()
                    .stroke(.white, lineWidth: strokeLineWidth)
                    .fill(.green)
                    .frame(width: circleSize, height: circleSize)
                
                Text(likeCount.formatted(.number.notation(.compactName)))
                    .contentTransition(.numericText())
            }
            .offset(x: showMyAvatar ? xOffset : 0)
        }
    }
    
    var noLikes: some View {
        ZStack {
            Group {
                Text(likeCount.formatted(.number.notation(.compactName)))
                    .contentTransition(.numericText())
                    .offset(x: myAvatarXOffset + 10 + 10)

                Circle()
                    .stroke(.white, lineWidth: strokeLineWidth)
                    .fill(.blue)
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: myAvatarXOffset)
            }
            .opacity(showMyAvatar ? 1 : 0)
            .scaleEffect(showMyAvatar ? 1 : 0)
            
            Image(systemName: showMyAvatar ? "heart.fill" : "heart")
                .resizable()
                .scaledToFit()
                .frame(width: heartSize, height: heartSize)
                .foregroundStyle(showMyAvatar ? Color.pink : .gray)
                .symbolEffect(.bounce, value: showMyAvatar)
        }
    }
    
    var placeholder: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .frame(width: heartSize, height: heartSize)
            
            HStack(spacing: 6) {
                HStack(spacing: -circleHStackSpacing) {
                    Circle()
                        .stroke(.white, lineWidth: strokeLineWidth)
                        .fill(.gray)
                        .frame(width: circleSize, height: circleSize)
                        .zIndex(2.0)
                    
                    Circle()
                        .frame(width: circleSize, height: circleSize)
                }
                
                Rectangle()
                    .cornerRadius(4)
                    .frame(width: 28, height: 12)
            }
        }
        .foregroundStyle(.gray)
    }
    
    var multipleLikes: some View {
        HStack(spacing: mainHStackSpacing) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: strokeLineWidth)
                    .fill(.blue)
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: myAvatarXOffset)
                    .opacity(showMyAvatar ? 1 : 0)
                    .scaleEffect(showMyAvatar ? 1 : 0)

                Image(systemName: showMyAvatar ? "heart.fill" : "heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: heartSize, height: heartSize)
                    .foregroundStyle(showMyAvatar ? Color.pink : .gray)
                    .symbolEffect(.bounce, value: showMyAvatar)
            }
            .zIndex(1.0)
            
            HStack(spacing: 4) {
                HStack(spacing: -circleHStackSpacing) {
                    Circle()
                        .stroke(.white, lineWidth: strokeLineWidth)
                        .fill(.green)
                        .frame(width: circleSize, height: circleSize)
                        .zIndex(2.0)
                        .offset(x: showMyAvatar ? xOffset : 0)
                    
                    Circle()
                        .foregroundStyle(.red)
                        .frame(width: circleSize, height: circleSize)
                        .zIndex(1.0)
                }
                
                Text(likeCount.formatted(.number.notation(.compactName)))
                    .contentTransition(.numericText())
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
    }
}


enum Status {
    case placeholder
    case noLikes
    case oneLike
    case multipleLikes
}
