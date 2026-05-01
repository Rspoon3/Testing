//
//  DeepLinkManager.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var isProcessing = false // Used for demo UI only
    @Published var currentDeepLink: DeepLink? // Used for demo UI only
    @Published var lastNetworkResponse: NetworkResponse? // Used for demo UI only
    
    private var cancellables = Set<AnyCancellable>()
    private let queue = DeepLinkQueue.shared
    private let networkService = FakeNetworkService.shared
    
    private init() {
        setupSubscription()
    }
    
    func setupSubscription() {
        // Create helper publishers
        let navigationDeepLinks = queue.sequentialPublisher.filter { deepLink in
            if case .navigateToColor = deepLink.action {
                return true
            }
            return false
        }
        
        let networkResponses = $lastNetworkResponse.compactMap { $0 }
        
        // Create a pipeline that waits for both deep link and network response
        Publishers.CombineLatest(navigationDeepLinks, networkResponses)
            .sink { [weak self] deepLink, networkResponse in
                Task { @MainActor in
                    await self?.processDeepLink(deepLink, with: networkResponse)
                }
            }
            .store(in: &cancellables)
        
        
        
//        
//        let sheetDeepLinks = queue.sequentialPublisher.filter { deepLink in
//            if case .presentColorSheet = deepLink.action {
//                return !deepLink.url.absoluteString.contains("purple")
//            }
//            return false
//        }
//        // Create a subscription for sheet deep links that just prints
//        sheetDeepLinks
//            .sink { [weak self] deepLink in
//                print("📋 Sheet deep link received: \(deepLink.url.absoluteString)")
//                // Remove from queue after printing
//                self?.queue.markProcessingComplete(id: deepLink.id)
//            }
//            .store(in: &cancellables)
    }
    
    func makeNetworkCall() async {
        let response = await networkService.fetchRandomValue()
        lastNetworkResponse = response
    }
    
    private func processDeepLink(_ deepLink: DeepLink, with networkResponse: NetworkResponse) async {
        // Mark as processing
        isProcessing = true
        currentDeepLink = deepLink
        
        defer {
            // Mark as completed
            currentDeepLink = nil
            isProcessing = false
        }
        
        print("🚀 Processing deep link: \(deepLink.url.absoluteString) with network value: \(networkResponse.value)")
        
        // Execute the deep link action
        switch deepLink.action {
        case .navigateToColor(let color):
            NavigationCoordinator.shared.navigate(to: .colorScreen(color))
            
        case .presentColorSheet(let color):
            NavigationCoordinator.shared.presentSheet(.colorSheet(color))
            
        case .unknown:
            print("⚠️ Unknown deep link action: \(deepLink.url.absoluteString)")
        case .setValue(_):
            print("Set value action not implemented")
        }
        
        // Notify queue that processing is complete
        queue.markProcessingComplete(id: deepLink.id)
    }
}

struct DeepLink {
    let id = UUID()
    let url: URL
    let action: DeepLinkAction
    let timestamp = Date()
    var status: DeepLinkStatus = .queued
    
    init(url: URL) {
        self.url = url
        self.action = DeepLinkAction.parse(from: url)
    }
}

enum DeepLinkStatus {
    case queued
    case processing
}

enum DeepLinkAction {
    case navigateToColor(String)
    case presentColorSheet(String)
    case setValue(Int)
    case unknown
    
    static func parse(from url: URL) -> DeepLinkAction {
        guard url.scheme == "testdrive" else { return .unknown }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch url.host {
        case "color":
            if let colorName = pathComponents.first {
                if url.queryItems?.contains(where: { $0.name == "sheet" && $0.value == "true" }) == true {
                    return .presentColorSheet(colorName)
                } else {
                    return .navigateToColor(colorName)
                }
            }
        case "value":
            if let valueString = pathComponents.first,
               let value = Int(valueString) {
                return .setValue(value)
            }
        default:
            break
        }
        
        return .unknown
    }
}

extension URL {
    var queryItems: [URLQueryItem]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        return components.queryItems
    }
}
