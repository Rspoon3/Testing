//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    static let width:CGFloat = 300
    let duration: Double = 10
    let animation = Animation.linear(duration: 20).repeatForever(autoreverses: false)
    @State private var offset = -width
    
    var body: some View {
        Rectangle()
            .frame(width: Self.width, height: 200)
            .foregroundColor(Color.green)
            .overlay(
                LinearGradient(gradient: .init(colors: [.green, .blue, .green]), startPoint: .leading, endPoint: .trailing)
                .offset(x: CGFloat(offset), y: 0)
                .mask(
                    Rectangle()
                    .onAppear{
                        withAnimation(self.animation){
                            self.offset = Self.width
                        }
                    }
                )
        )
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


