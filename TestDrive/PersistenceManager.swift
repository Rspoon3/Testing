//
//  PersistenceManager.swift
//  Testing
//
//  Created by Ricky on 11/3/24.
//

import SwiftUI
import OSLog

@MainActor
public final class PersistenceManager: ObservableObject, Sendable {
    public static let shared = PersistenceManager()
    private let logger = Logger(category: PersistenceManager.self)

    private init(){
        logger.notice("numberOfLaunches: \(self.numberOfLaunches.formatted(), privacy: .public)")
        logger.notice("numberOfActivations: \(self.numberOfActivations.formatted(), privacy: .public)")
    }
    
    @AppStorage("numberOfLaunches")
    public var numberOfLaunches: Int = 0
    
    @AppStorage("numberOfActivations")
    public var numberOfActivations: Int = 0
    
    @AppStorage("deviceFrameCreations")
    public var deviceFrameCreations: Int = 0
    
    @AppStorage("lastReviewPromptDate")
    public var lastReviewPromptDate: Date?
    
    public func setLastReviewPromptDateToNow() {
        lastReviewPromptDate = .now
    }
}


extension Date: @retroactive RawRepresentable {
    public var rawValue: String {
        self.timeIntervalSinceReferenceDate.description
    }
    
    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}
