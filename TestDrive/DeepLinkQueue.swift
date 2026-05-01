//
//  DeepLinkQueue.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DeepLinkQueue: ObservableObject {
    static let shared = DeepLinkQueue()
    
    @Published private(set) var queue: [DeepLink] = []
    private let sequentialSubject = CurrentValueSubject<DeepLink?, Never>(nil) // Sequential emissions
    private let immediateSubject = CurrentValueSubject<DeepLink?, Never>(nil) // Immediate emissions
    
    var queueCount: Int {
        queue.filter { $0.status == .queued }.count
    }
    
    private var isProcessing: Bool {
        queue.contains { $0.status == .processing }
    }
    
    var sequentialPublisher: AnyPublisher<DeepLink, Never> {
        return sequentialSubject
            .compactMap { $0 }
            .map {
                print("In sequentialPublisher", $0.url)
                return $0
            }
            .eraseToAnyPublisher()
    }
    
    var immediatePublisher: AnyPublisher<DeepLink, Never> {
        return immediateSubject
            .compactMap { $0 }
            .map {
                print("In immediatePublisher", $0.url)
                return $0
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    private init() {}
    
    // MARK: - Public
    
    func enqueue(url: URL) {
        let deepLink = DeepLink(url: url)
        
        print("🔗 Enqueuing deep link: \(url.absoluteString)")
        queue.append(deepLink)
        
        // Emit immediately for consumers that need instant processing
        immediateSubject.send(deepLink)
        print("immediateSubject send 1")
        
        // Only start sequential processing if we're not already processing an item
        guard !isProcessing else { return }
        processQueue()
    }
    
    func markProcessingComplete(id: UUID) {
        // Find the deep link before removing it
        let completedDeepLink = queue.first { $0.id == id }
        
        // Remove the specific item by ID
        queue.removeAll { $0.id == id }
        
        // Clear subjects if they contain the completed deep link
        if let completed = completedDeepLink {
            if sequentialSubject.value?.id == completed.id {
                sequentialSubject.send(nil)
                print("sequentialSubject send nil")
            }
            if immediateSubject.value?.id == completed.id {
                immediateSubject.send(nil)
                print("immediateSubject send nil")
            }
        }
        
        // Continue processing the next item in queue if any
        processQueue()
    }
    
    // MARK: - Private
    
    private func processQueue() {
        // Find first queued item
        guard let index = queue.firstIndex(where: { $0.status == .queued }) else { return }
        guard !isProcessing else { return }
        
        // Mark as processing
        queue[index].status = .processing
        let deepLink = queue[index]
        print("📤 Emitting deep link from queue: \(deepLink.url.absoluteString)")
        
        // Emit the deep link for processing
        sequentialSubject.send(deepLink)
        print("sequentialSubject send 1")
    }
}
