//
//  PurpleSheetModel.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PurpleSheetModel: ObservableObject {
    
    @Published var lastPurpleSheetAction: String = ""
    @Published var purpleSheetCount: Int = 0
    @Published var lastProcessedTime: Date?
    @Published var isPurpleSheetPresented: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let queue = DeepLinkQueue.shared
    
    func setupSubscription() {
        // Create helper publisher for purple sheet deep links
        let purpleSheetDeepLinks = queue.sequentialPublisher.filter { deepLink in
            if case .presentColorSheet(let color) = deepLink.action, color.lowercased() == "purple" {
                return true
            }
            return false
        }
        
        // Subscribe to purple sheet deep links and process immediately
        purpleSheetDeepLinks
            .sink { [weak self] deepLink in
                Task { @MainActor in
                    await self?.processPurpleSheetDeepLink(deepLink)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processPurpleSheetDeepLink(_ deepLink: DeepLink) async {
        print("💜 Processing purple sheet deep link: \(deepLink.url.absoluteString)")
        
        // Update the model state
        lastPurpleSheetAction = deepLink.url.absoluteString
        purpleSheetCount += 1
        lastProcessedTime = Date()
        
        print("💜 Purple sheet count: \(purpleSheetCount)")
        
        // Actually present the purple sheet
        if case .presentColorSheet(let color) = deepLink.action, color.lowercased() == "purple" {
            isPurpleSheetPresented = true
        }
        
        // Remove from queue immediately (demonstrates immediate processing)
        queue.markProcessingComplete(id: deepLink.id)
    }
}
