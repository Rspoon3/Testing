//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = CarouselRepresentableViewModel()
    private let shadowBottomPadding: CGFloat = 20
    
    var body: some View {
        ScrollView {
            Text("TOP")
            Text("Index: \(model.currentIndex.item)")
            CarouselRepresentable(model: model)
                .frame(height: model.height + shadowBottomPadding)
                .onAppear{
                    model.scrollToMiddle()
//                    model.startTimer()
                    model.configureScrollObserver()
                }
            Text("Bottom")
            
            ForEach(0..<100) {_ in
                Color.orange
                    .frame(height: 100)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


