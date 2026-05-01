//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 50) {
            LineAndHalfCircleShape()
                .stroke(Color.blue, lineWidth: 15)
                .overlay {
                    HalfCircleDots()
                }
            
            LineAndHalfCircleShape()
                .stroke(Color.blue, lineWidth: 15)
                .overlay {
                    HalfCircleDots()
                }
                .rotationEffect(.degrees(180))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
