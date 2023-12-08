//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/8/23.
//

import SwiftUI

struct ContentView: View {
    let cache = AsyncCache<Void>()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<100, id: \.self) { i in
                    NavigationLink {
                        DetailsView(cache: cache, i: i)
                    } label: {
                        Text(i.formatted())
                    }
                    .task {
                        try? await cache.fetch(key: "\(i)") {
                            try await Task.sleep(for: .seconds(3))
                        }
                    }
                }
            }
        }
    }
}

#Preview("ContentView") {
    ContentView()
}

