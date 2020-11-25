//
//  Results.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/24/20.
//

import SwiftUI


struct Results: Identifiable{
    let id = UUID()
    let steps: [Steps]
    let challenge: Challenge
    
    var sum: Int{
        steps.reduce(0) { $0 + $1.value }
    }
}
