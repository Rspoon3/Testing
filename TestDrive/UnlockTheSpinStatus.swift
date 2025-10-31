//
//  UnlockTheSpinStatus.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/31/25.
//

import Foundation
import CaseDetectionMacro

/// Status for unlock the spin progress.
@CaseAssociatedValueDetection
public enum UnlockTheSpinStatus: Codable, Sendable, Equatable {
    case ineligible
    case eligible(stepsComplete: Int, stepsTotal: Int)
}

final class StatusClass {
    let status: UnlockTheSpinStatus = .ineligible
    
    func foo() {
        print(status.eligible?.stepsComplete)
        print(status.eligible?.stepsTotal)
    }
}
