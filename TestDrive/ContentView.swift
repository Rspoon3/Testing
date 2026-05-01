//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    
    var body: some View {
        Text("Testing")
            .onAppear {
                WidgetCenter.shared.reloadAllTimelines()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
