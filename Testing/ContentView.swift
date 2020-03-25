//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var animate = false
    
    var body: some View {
        AnimatedGradientView1()
            .frame(width: 200, height: 200)
    }
}

struct AnimatedGradientView1: View {
    
    @State var gradient = [Color.green, Color.red]
    @State var startPoint = UnitPoint(x: 0, y: 0)
    @State var endPoint = UnitPoint(x: 0, y: 2)
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(gradient: Gradient(colors: self.gradient), startPoint: self.startPoint, endPoint: self.endPoint))
            .frame(width: 256, height: 256)
            .onTapGesture {
                withAnimation (.easeInOut(duration: 3)){
                    self.startPoint = UnitPoint(x: 1, y: -1)
                    self.endPoint = UnitPoint(x: 0, y: 1)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
