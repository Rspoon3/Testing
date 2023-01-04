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
            ZStack {
                if debug {
                    HStack(spacing: 0) {
                        Color.blue
                            .frame(width: spacing)
                        Color.red
                            .frame(width: spacing)
                        Spacer()
                        Color.red
                            .frame(width: spacing)
                        Color.blue
                            .frame(width: spacing)
                    }
                }
                
                ScrollView {
                    Text("TOP")
                    Text("Index: \(model.currentIndex.item)")
                    CarouselRepresentable(model: model)
                        .frame(height: model.height + shadowBottomPadding)
                        .opacity(debug ? 0.75 : 1)
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
                            .padding(.horizontal, spacing)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Toggle("Debug", isOn: $debug.animation())
                        .toggleStyle(.switch)
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


