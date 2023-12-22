//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/8/23.
//

import SwiftUI

struct ContentView: View {
    let repository = Repository()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<100, id: \.self) { i in
                    NavigationLink {
//                        DetailsView(cache: cache, i: i)
                    } label: {
                        Text(i.formatted())
                    }
                    .task {
                        do {
//                            let _ = try await cache.fetch(input: i)
                            let value = try await repository.fetch(input: i)
                        } catch {
                            print(error.localizedDescription)
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

