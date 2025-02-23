//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

enum Route {
    case details
}

@MainActor
@Observable
final class NavigationManager {
    var path = NavigationPath()
}

struct ContentView: View {
    @State private var navigationManager = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            HomeView()
                .environment(navigationManager)
        }
    }
}

final class Empty { }
struct Test {
    var empty = Empty() // Comment this out to make it work
}

struct HomeView: View {
    private let test = Test()
    @Environment(NavigationManager.self) private var navigationManager
    
    var body: some View {
        Form {
            Button("Go To Details View") {
                navigationManager.path.append(Route.details)
            }
        }
        .navigationTitle("Home View")
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .details:
                DetailsView()
                    .environment(navigationManager)
            }
        }
    }
}

@MainActor
@Observable
final class DetailsViewModel {
    var fullScreenItem: Item?
    
    init() {
        print("DetailsViewModel Init")
    }
    
    deinit {
        print("DetailsViewModel Deinit")
    }
}

struct Item: Identifiable {
    let id = UUID()
    let value: Int
}

struct DetailsView: View {
    @State private var viewModel = DetailsViewModel()
    @Environment(NavigationManager.self) private var navigationManager
    
    var body: some View {
        Button("Show Full Screen Cover") {
            viewModel.fullScreenItem = .init(value: 4)
        }
        .navigationTitle("Details View")
        .fullScreenCover(item: $viewModel.fullScreenItem) { item in
            NavigationStack {
                FullScreenView(item: item)
                    .navigationTitle("Full Screen Item: \(item.value)")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                viewModel.fullScreenItem = nil
                                
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    navigationManager.path.removeLast()
                                }
                            }
                        }
                    }
            }
        }
    }
}

struct FullScreenView: View {
    @Environment(\.dismiss) var dismiss
    let item: Item
    
    var body: some View {
        Text("Full Screen View \(item.value)")
            .navigationTitle("Full Screen View")
    }
}


#Preview {
    ContentView()
}
