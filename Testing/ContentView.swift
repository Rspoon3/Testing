//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ColorModel : Identifiable{
    let id = UUID()
    let color: Color
    let front : Bool
    let back : Bool
    
    static let colors : [ColorModel] = [
        .init(color: .orange, front: false, back: true),
        .init(color: .blue, front: true, back: true),
        .init(color: .purple, front: true, back: true),
        .init(color: .green, front: true, back: true),
        .init(color: .green, front: true, back: true),
        .init(color: .green, front: true, back: true),
        .init(color: .green, front: true, back: false),
        
    ]
}

struct ContentView : View {
    let width: CGFloat = 100
    
    var body : some View{
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: -20){
                ForEach(ColorModel.colors) { model in
                    Parallelogram(cutBack: model.front, cutFront: model.back)
                        .frame(width: self.width)
                        .foregroundColor(model.color)
                }
                Spacer()
            }
            .mask(
                Capsule()
            )
                .frame(height: 10)
        }
    }
}

struct Parallelogram: Shape {
    var cutBack  : Bool = true
    var cutFront : Bool = true
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - (cutFront ? rect.width / 4 : 0), y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + (cutBack ? rect.width / 4 : 0), y: rect.minY))
        
        return path
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

