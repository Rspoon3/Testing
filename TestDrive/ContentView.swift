//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var deepLinkQueue: DeepLinkQueue
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var counterModel: CounterModel
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            QueueDemoView()
                .environmentObject(deepLinkQueue)
                .environmentObject(deepLinkManager)
                .environmentObject(navigationCoordinator)
                .environmentObject(counterModel)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Queue Demo")
                }
                .tag(0)
            
            SettingsView()
                .environmentObject(deepLinkQueue)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
        }
        .onReceive(deepLinkQueue.immediatePublisher) { deepLink in
            print("RSW immediatePublisher: \(deepLink.url)")
            if case .presentColorSheet(let color) = deepLink.action, color.lowercased() == "purple" {
                selectedTab = 1
                print("Going to tab 1")
            }
        }
    }
}

struct QueueDemoView: View {
    @EnvironmentObject private var deepLinkQueue: DeepLinkQueue
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var counterModel: CounterModel
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            VStack(spacing: 24) {
                Text("TestDrive Deep Link Queuing")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                // Queue Status
                VStack(spacing: 12) {
                    HStack {
                        Text("Queue Status:")
                            .font(.headline)
                        Spacer()
                        if deepLinkManager.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing")
                                    .font(.caption)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Queue Count:")
                        Spacer()
                        Text("\(deepLinkQueue.queueCount)")
                            .fontWeight(.semibold)
                            .foregroundColor(deepLinkQueue.queueCount > 0 ? .orange : .green)
                    }
                    
                    if let currentLink = deepLinkManager.currentDeepLink {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Currently Processing:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(currentLink.url.absoluteString)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    
                    if let networkResponse = deepLinkManager.lastNetworkResponse {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Network Response:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Text("Value: \(networkResponse.value)")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(networkResponse.timestamp.formatted(.dateTime.hour().minute().second()))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Counter Status
                VStack(spacing: 12) {
                    Text("Counter Model:")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Current Value:")
                            Spacer()
                            Text("\(counterModel.currentValue)")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        if !counterModel.lastProcessedDeepLink.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Last Processed:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(counterModel.lastProcessedDeepLink)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Example Deep Links
                VStack(alignment: .leading, spacing: 16) {
                    Text("Try These Deep Links:")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        // Navigation examples
                        Group {
                            DeepLinkButton("Red Screen", url: "testdrive://color/red")
                            DeepLinkButton("Blue Screen", url: "testdrive://color/blue")
                            DeepLinkButton("Green Screen", url: "testdrive://color/green")
                        }
                        
                        Divider()
                        
                        // Sheet examples
                        Group {
                            DeepLinkButton("Purple Sheet", url: "testdrive://color/purple?sheet=true")
                            DeepLinkButton("Orange Sheet", url: "testdrive://color/orange?sheet=true")
                            DeepLinkButton("Pink Sheet", url: "testdrive://color/pink?sheet=true")
                        }
                    }
                }
                
                Spacer()
                
                // Quick test buttons
                VStack(spacing: 8) {
                    Text("Queue Multiple Links:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Queue 3 Links") {
                        queueMultipleLinks()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationDestination(for: ColorDestination.self) { destination in
                switch destination {
                case .color(let colorName):
                    ColorScreen(colorName: colorName)
                }
            }
        }
        .sheet(item: $navigationCoordinator.presentedSheet) { sheet in
            switch sheet {
            case .colorSheet(let colorName):
                ColorSheet(colorName: colorName)
            }
        }
        .onAppear {
//            deepLinkQueue.enqueue(url: .init(string: "testdrive://color/red")!)
            queueMultipleLinks()
        }
        .task {
            await deepLinkManager.makeNetworkCall()
        }
    }
    
    private func queueMultipleLinks() {
        let links = [
            "testdrive://color/purple?sheet=true", // This will be caught by PurpleSheetModel
//            "testdrive://color/red",
//            "testdrive://color/green",
//            "testdrive://color/blue?sheet=true",
//            "testdrive://value/42",  // This will process immediately (out of order)
        ]
        
        for link in links {
            if let url = URL(string: link) {
                deepLinkQueue.enqueue(url: url)
            }
        }
    }
}

struct DeepLinkButton: View {
    let title: String
    let urlString: String
    
    init(_ title: String, url: String) {
        self.title = title
        self.urlString = url
    }
    
    var body: some View {
        Button(action: {
            if let url = URL(string: urlString) {
                DeepLinkQueue.shared.enqueue(url: url)
            }
        }) {
            HStack {
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Text(urlString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(DeepLinkQueue.shared)
        .environmentObject(DeepLinkManager.shared)
        .environmentObject(NavigationCoordinator.shared)
        .environmentObject(CounterModel.shared)
}
