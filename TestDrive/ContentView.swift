//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct User: Identifiable {
    let id: Int
    var name: String
    var score: Int
}

struct ContentView: View {
        @State
        var yPos: Double = 0.75

        @State
        var threshold: Double = 0.5

        @State
        var radius: Double = 15

        var body: some View {
            VStack(alignment: .leading) {
                Text("Preview")
                Color.blue.mask {
                    Canvas { ctx, size in
                        ctx.addFilter(.alphaThreshold(min: threshold))

                        ctx.addFilter(.blur(radius: radius))

                        // This drawing operation needs to happen on a separate layer
                        // for the effect to work.
                        ctx.drawLayer { ctx in
                            var rect = CGRect(x: 10, y: 50, width: 150, height: 150)

                            ctx.fill(Circle().path(in: rect), with: .color(.black))

                            rect.origin.x += yPos * (size.width - rect.width - 20.0)

                            ctx.fill(Circle().path(in: rect), with: .color(.black))
                        }
                    }
                }

                Group {
                    Text("y-Position")
                    Slider(value: $yPos)

                    Divider()

                    Text("Threshold")
                    Slider(value: $threshold, in: 0.01 ... 0.99)

                    Divider()

                    Text("Radius")
                    Slider(value: $radius, in: 0 ... 30)
                }

            }
            .padding()
            .font(.caption2)
        }
    }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 11")
    }
}
