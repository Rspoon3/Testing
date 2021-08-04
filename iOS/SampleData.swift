//
//  SampleData.swift
//  SampleData
//
//  Created by Richard Witherspoon on 8/1/21.
//

import Foundation

struct SampleData: Identifiable{
    let id = UUID()
    let date: Date
    let value: Double
}

extension Sequence where Element == SampleData {
    func sum() -> Double {
        reduce(0) { value, data in
            value + data.value
        }
    }
}
