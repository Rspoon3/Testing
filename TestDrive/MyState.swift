//
//  MyState.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/31/25.
//

import Foundation
import CaseDetectionMacro

@CaseDetection
enum MyState {
    case connecting
    case messaging(message: String)
    case error(localizedDescription: String)
    case sent(date: Date, count: Int)
    case eligible(stepsComplete: Int, stepsTotal: Int)
}

final class Tester {
    let state: MyState = .connecting
    
    func foo() {
        print(state.isConnecting)
    }
}
