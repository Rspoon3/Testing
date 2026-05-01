//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var blur = 0.0
    
    var body: some View {
        VStack{
            Text(blur.formatted())
            Slider(value: $blur, in: 0...20)
            
            Image("dog")
                .resizable()
//                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .blur(radius: blur)
                .border(Color.black)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
