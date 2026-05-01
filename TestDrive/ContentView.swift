//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import SFSymbols
import SFSafeSymbols

struct ContentView: View {
    var body: some View {
        Image(symbol: .number00Circle)
        Image(systemSymbol: .smiley)
        Label("Test", symbol: .book)
        Label("test", symbol: .bag, textColor: .brown)
            .foregroundColor(.red)
        Label("Test", systemSymbol: .book)
            .foregroundColor(.red)
        
        Button("Test", symbol: .car) {
            
        }
        
        Button("Test", systemImage: "car") {
            
        }
        
        
        Text(SFSymbols.SFSymbol.allSymbols.count.formatted())
        Text(SFSafeSymbols.SFSymbol.allSymbols.count.formatted())
    }
}

#Preview {
    ContentView()
}
