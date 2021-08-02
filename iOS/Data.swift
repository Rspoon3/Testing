//
//  Data.swift
//  Data
//
//  Created by Richard Witherspoon on 8/1/21.
//

import Foundation

struct Data: Identifiable{
    let id = UUID()
    let date: Date
    let value: Int
}

extension Sequence where Element == Data {
    func sum() -> Int {
        reduce(0) { value, data in
            value + data.value
        }
    }
}
