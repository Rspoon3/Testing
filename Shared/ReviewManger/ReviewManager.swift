//
//  ReviewManager.swift
//  Primes
//
//  Created by Ricky on 11/25/24.
//

import Foundation
import StoreKit
import OSLog

@MainActor
public struct ReviewManager {
    private let key = "lastReviewPromptDate"
    private let userDefaults = UserDefaults.standard

    public init() {}
    
    public func askForReview(collectedCount: Int) {
        if let date = userDefaults.object(forKey: key) as? Date,
           date <= Date.now.adding(1, .day) {
            print("Last review prompt date to recent: \(date).")
            return
        }
        
        guard
            let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            collectedCount > 3
        else {
            return
        }
        
        userDefaults.set(Date.now, forKey: key)
        AppStore.requestReview(in: scene)
    }
}

