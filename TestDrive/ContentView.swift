//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@MainActor
struct ContentView: View {
    @State private var count = 0
    @State private var dates: [Date] = []
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Text(count.formatted())
                        .monospaced()
                        .animation(.default, value: count)
                        .contentTransition(.numericText())
                    
                    ForEach(dates, id: \.self) { date in
                        Text(date.formatted())
                            .id(date)
                    }
                }
                .task {
                    for await date in Timer.stream(every: .seconds(1), endIn: .minutes(1)) {
                        withAnimation {
                            proxy.scrollTo(dates.last)
                        }
                        dates.append(date)
                        count += 1
                    }
                }
            }
            .navigationTitle("List")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
