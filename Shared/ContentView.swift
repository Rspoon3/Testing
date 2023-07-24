//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var canvasViewModel = PKCanvasViewModel()
    let test = ["Author", "Genre", "Pages", "Book Type", "Start Date", "End Date"]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            PKCanvas(viewModel: canvasViewModel)
                .border(Color.green)
            
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Title")
                            .font(.headline)
                        Divider()
                    }
                    
                    LazyVGrid(columns: [.init(), .init()]) {
                        ForEach(test, id: \.self) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(item)
                                    .font(.headline)
                                Divider()
                            }
                        }
                    }
                }
                
                VStack(spacing: 30) {
                    ForEach(0..<20, id: \.self) { _ in
                        Divider()
                    }
                }
                .padding(.top)
            }
            .border(Color.blue)
            
            VStack(alignment: .leading, spacing: 30) {
                Text("Book I")
                    .foregroundColor(.white)
                    .frame(minWidth: 100)
                    .font(.headline)
                    .padding(.all, 8)
                    .background(
                        Capsule()
                            .foregroundColor(.gray)
                    )
                
                Image("mockingBird")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(8)
                
                HStack {
                    Image(systemName: "star.fill")
                    Image(systemName: "star.fill")
                    Image(systemName: "star.fill")
                    Image(systemName: "star.fill")
                    Image(systemName: "star.fill")
                }
                .font(.title)
                .symbolRenderingMode(.multicolor)
            }
            .padding()
            .border(Color.red)
            .background {
                Color.white
                    .ignoresSafeArea()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
        .previewInterfaceOrientation(.landscapeLeft)
        .navigationViewStyle(.stack)
    }
}
