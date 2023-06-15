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

    var body: some View {
        VStack {
            Text("ID: \(id?.formatted() ?? "None")")
                .onTapGesture {
                    id = 0
                }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(array, id: \.self) { i in
                        colors[i % 4]
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .aspectRatio(16.0 / 9.0, contentMode: .fit)
                            .containerRelativeFrame(.horizontal)
                            .id(i)
                            .scrollTransition(axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.75)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $id)
            .scrollTargetBehavior(.paging)
            .onAppear {
                id = array.count / 2
            }
        }
    }
}

#Preview {
    ContentView()
}
