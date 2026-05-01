//
//  SkipOption.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/14/25.
//

import Foundation

enum SkipOption: Int, CaseIterable {
    case none = 0, five, thirty, sixty, restOfDay, sunset

    var label: String {
        switch self {
        case .none: return "None"
        case .five: return "5 min"
        case .thirty: return "30 min"
        case .sixty: return "60 min"
        case .restOfDay: return "Rest of Day"
        case .sunset: return "Until Sunset"
        }
    }

    var icon: String {
        switch self {
        case .none: return "nosign"
        case .five: return "timer"
        case .thirty: return "hourglass"
        case .sixty: return "clock"
        case .restOfDay: return "sun.max.fill"
        case .sunset: return "sunset.fill"
        }
    }
}
