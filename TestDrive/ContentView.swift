//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    private let scale = 0.88
    private let offset: Double = -4
    private let cornerRadius: CGFloat = 8
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image("dog")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: (geo.size.width * 0.9) * scale,
                        height: (geo.size.width * 0.9 ) * scale / 2
                    )
                    .cornerRadius(8)
                    .clipped()
                    .blur(radius: 40)
//                    .border(Color.red)
                    .clipShape(
                        Path { path in
//                            path.move(to: CGPoint(x : path.boundingRect.minX, y:  path.boundingRect.minY))
//                            path.addLine (to : CGPoint(x:  path.boundingRect.maxX, y:  path.boundingRect.minY))
//                            path.addLine (to : CGPoint(x:  path.boundingRect.maxX, y:  path.boundingRect.maxY))
//                            path.addLine (to : CGPoint(x:  path.boundingRect.minX, y:  path.boundingRect.maxY))
//                            path.addLine (to : CGPoint(x:  path.boundingRect.minX, y:  path.boundingRect.minY))
                            
                            path.addLines([
                                CGPoint(x: 20, y: 0),
                                CGPoint(x: (geo.size.width * 0.9) * scale - 20, y: 0),
                                CGPoint(x: (geo.size.width * 0.9) * scale - 20, y: 300),
                                CGPoint(x: 20, y: 300)
                            ])

//                            path.closeSubpath()
                        }
                    )
                    .padding(.bottom, offset)

                Image("dog")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: geo.size.width / 2)
                    .cornerRadius(cornerRadius)
                    .clipped()
                    .opacity(0.16)
//                    .border(Color.green)
            }
            .frame(width: 300)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 100)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
