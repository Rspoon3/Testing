//
//  HealthKitRequester.swift
//  SyncSpin
//
//  Created by Ricky on 2/3/25.
//

import Foundation
import HealthKit

public struct HealthKitRequester {
    private let healthStore = HKHealthStore()
    private let typesToRead: Set = [
        HKObjectType.activitySummaryType(),
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    ]
    
    public var shouldShow: Bool {
        let statuses = typesToRead.map {
            healthStore.authorizationStatus(for: $0)
        }
        
        return statuses.contains(where: {$0 == .notDetermined})
    }
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public
    
    public func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(
            toShare: [],
            read: typesToRead
        )
    }
}
