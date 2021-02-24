//
//  Parallelogram.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/23/21.
//

import SwiftUI


struct Parallelogram: Shape {
    var cutBack  : Bool = true
    var cutFront : Bool = true
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - (cutFront ? rect.width / 10 : 0), y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + (cutBack ? rect.width / 4 : 0), y: rect.minY))
        
        return path
    }
}

struct Parallelogram_Previews: PreviewProvider {
    static var previews: some View {
        Parallelogram()
    }
}
