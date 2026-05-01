//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var searchText = ""
    @State private var debouncedText = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            TextField("Search...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchText) { _, newValue in
                    print("Searchtext: \(newValue)")
                }
                .onDebounceChange(of: searchText) { newValue in
                    debouncedText = newValue
                    print("Debounce: \(newValue)")
                }
            
            Text("Current: \(searchText)")
            Text("Debounced: \(debouncedText)")
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
