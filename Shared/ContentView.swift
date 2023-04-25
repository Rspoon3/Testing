//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = CarouselRepresentableViewModel()
    @State private var debug = false
    private let shadowBottomPadding: CGFloat = 20
    private let spacing: CGFloat = 12
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ScrollView {
                    VStack {
                        CarouselRepresentable(model: model, width: geo.size.width)
                            .frame(height: geo.size.width / 2 + 150)
                            .background(Color.blue.opacity(0.1))
                        Text("This is a long sentence")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


