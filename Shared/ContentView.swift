//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Models

struct ContentView: View {
    let item = Item()
    
#if DEBUG
    public let title = "Debug"
#else
    public let title = "Else Block"
#endif
    
    
    
    var body: some View {
        VStack {
            Text("Title: \(title)")
            Text(item.title)
        }
            .font(.largeTitle)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
