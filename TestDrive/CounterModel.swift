//
//  CounterModel.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CounterModel: ObservableObject {
    static let shared = CounterModel()
    
    @Published var currentValue: Int = 0
    @Published var lastProcessedDeepLink: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let queue = DeepLinkQueue.shared
    
    private init() {
        setupSubscription()
    }
    
    private func setupSubscription() {
        // Create helper publisher for value deep links
        let valueDeepLinks = queue.immediatePublisher.filter { deepLink in
            if case .setValue = deepLink.action {
                return true
            }
            return false
        }
        
        // Subscribe to value deep links and process immediately (out of order)
        valueDeepLinks
            .sink { [weak self] deepLink in
                Task { @MainActor in
                    await self?.processValueDeepLink(deepLink)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processValueDeepLink(_ deepLink: DeepLink) async {
        print("🔢 Processing value deep link: \(deepLink.url.absoluteString)")
        
        if case .setValue(let value) = deepLink.action {
            // Update the counter value
            currentValue = value
            lastProcessedDeepLink = deepLink.url.absoluteString
            
            print("🔢 Counter updated to: \(value)")
        }
        
        // Remove from queue immediately (no delay - demonstrates out of order processing)
        queue.markProcessingComplete(id: deepLink.id)
    }
}