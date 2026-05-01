//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Text("IntStore Value: \(viewModel.value)")
                    .font(.title)

                HStack(spacing: 20) {
                    Button("Test \(viewModel.count)") {
                        Task {
                            await viewModel.test.increment()
                        }
                    }
                    .task {
                        await viewModel.watchTest()
                    }
                    
                    Button("-") {
                        viewModel.decrementIntStore()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("+") {
                        viewModel.incrementIntStore()
                    }
                    .buttonStyle(.borderedProminent)
                    .onAppear {
                        DispatchQueue.global(qos: .userInitiated).async {
                            DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
                                viewModel.incrementIntStore()
                                
//                                Task {
//                                    await viewModel.test.increment()
//                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
