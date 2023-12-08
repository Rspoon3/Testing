//
//  DetailsView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct DetailsView: View {
    let cache: AsyncCache<Void>
    let i: Int
    @State private var inProgress = 0
    @State private var fetchedCount = 0

    var body: some View {
        VStack(alignment: .leading) {
            Text(i.formatted())
            Text("In Progress: \(inProgress)")
                .contentTransition(.numericText())
            Text("Fetched: \(fetchedCount.formatted())")
            Button("Clear Cache") {
                Task {
                    await cache.clear()
                }
            }
        }
        .contentTransition(.numericText())
        .task {
            for await value in await cache.inProgressCountPublisher.values {
                withAnimation {
                    inProgress = value
                }
            }
        }
        .task {
            for await value in await cache.fetchedCountPublisher.values {
                withAnimation {
                    fetchedCount = value
                }
            }
        }
    }
}

#Preview("DetailsView") {
    DetailsView(cache: .init(), i: 0)
}
