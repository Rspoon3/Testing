//
//  Date+Extension.swift
//  Primes
//
//  Created by Ricky on 11/25/24.
//

import Foundation

extension Date {
    func adding(_ value: Int, _ component: Calendar.Component) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self)!
    }
}
