//
//  TimePeriod.swift
//  Testing
//
//  Created by Ricky on 3/2/25.
//

import Foundation

enum TimePeriod: String, CaseIterable {
    case daily = "Day"
    case weekly = "Week"
    case monthly = "Month"
    case yearly = "Year"
    
    var calendarComponents: Calendar.Component {
        switch self {
        case .daily: .day
        case .weekly: .weekOfYear
        case .monthly: .month
        case .yearly: .year
        }
    }
    
    var dateFormatStyle: Date.FormatStyle {
        switch self {
        case .daily: .dateTime.day()
        case .weekly: .dateTime.month(.abbreviated).day()
        case .monthly: .dateTime.month(.abbreviated)
        case .yearly: .dateTime.year()
        }
    }
    
    var snapInterval: DateComponents {
        switch self {
        case .daily: DateComponents(hour: 1)
        case .weekly: DateComponents(weekday: 1)
        case .monthly: DateComponents(month: 1)
        case .yearly: DateComponents(year: 1)
        }
    }
}
