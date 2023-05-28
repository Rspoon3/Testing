//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    let test = ["Author", "Genre", "Pages", "Book Type", "Start Date", "End Date"]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(alignment: .top, spacing: 30) {
                //
                //            .frame(maxWidth: .infinity, alignment: .leading)
                
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
                .background {
                    Color.white
                        .padding(.trailing, -50)
                        .padding(.bottom, -50)
                        .ignoresSafeArea()
                }
                //                .frame(maxHeight: .infinity, alignment: .top)
                
                
                VStack(spacing: 20) {
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
                //                .background(Color.red)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .leading)
//            .background(Color.blue)
            .background {
                LazyVStack(spacing: 30) {
                    ForEach(0..<300, id: \.self) { _ in
//                        Divider()
                    }
                }
            }
            
            //            Color.clear
            //        }
            //        .frame(maxWidth: .infinity, alignment: .leading)
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
