//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @AppStorage("count", store: .shared) var count = 0
    
    var body: some View {
        Button("Count: \(count)") {
            count += 1
            WidgetCenter.shared.reloadAllTimelines()
        }
        .font(.title)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
