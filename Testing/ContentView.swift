//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct AnimatedGradientRectangle: View {
    let backgroundColor: Color
    let gradientColors: [Color]
    let duration: Double

    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader{ geo in
            Rectangle()
                .foregroundColor(self.backgroundColor)
                .overlay(
                    LinearGradient(gradient: .init(colors: self.gradientColors), startPoint: .leading, endPoint: .trailing)
                        .offset(x: self.offset, y: 0)
                        .mask(
                            Rectangle()
                                .onAppear{
                                    self.offset = -geo.size.width
                                    withAnimation(Animation.linear(duration: self.duration).repeatForever(autoreverses: false)){
                                        self.offset = geo.size.width
                                    }
                            }
                    )
            )
        }
    }
}

struct ContentView: View {
    var body: some View {
        AnimatedGradientRectangle(backgroundColor: .blue, gradientColors: [.blue, .red, .blue], duration: 3)
            .frame(height: 100)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


