//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var id: Int?
    let array = Array(0..<1_000)
    let colors = [
        Color.blue,
        Color.red,
        Color.orange,
        Color.purple
    ]
    @State var x = 0.0

    var body: some View {
        VStack {
            Text("ID: \(id?.formatted() ?? "None")")
                .onTapGesture {
                    withAnimation {
                        id = 0
                    }
                }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: -100) {
                    ForEach(array, id: \.self) { i in
                        colors[i % 4]
                            .cornerRadius(10)
                            .aspectRatio(16.0 / 9.0, contentMode: .fit)
                            .containerRelativeFrame(.horizontal, count: 10, span: 8, spacing: 0)
                            .visualEffect { content, proxy in
                                content
                                    .scaleEffect(size(using: proxy))
                            }
                           
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $id)
//            .scrollTargetBehavior(.paging)
            .onAppear {
                id = array.count / 2
            }
        }
    }
    
    func size(using proxy: GeometryProxy) -> Double {
        let scrollViewWidth = proxy.bounds(of: .scrollView)!.width
        let position = proxy.frame(in: .scrollView).midX
        let distanceFromCenter = abs(scrollViewWidth / 2 - position)
        
        
        let value = 1 - distanceFromCenter / scrollViewWidth
        print(scrollViewWidth, position, distanceFromCenter, value)
        
        return value
    }
}

#Preview {
    ContentView()
}
