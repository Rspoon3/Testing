//
//  Int+IsPrime.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import Foundation

extension Int {
    func isPrime(_ n: Int) -> Bool {
        guard n > 1 else { return false }
        for i in 2..<Int(sqrt(Double(n))) + 1 {
            if n % i == 0 { return false }
        }
        return true
    }
}
