//
//  TimerDuration.swift
//  
//
//  Created by Richard Witherspoon on 12/13/23.
//

import Foundation

public enum TimerDuration: Sendable, Comparable {
    case hour(Double)
    case minutes(Double)
    case seconds(Double)
    case milliseconds(Double)
    
    var timeInterval: TimeInterval {
        switch self {
        case .hour(let value):
            return TimeInterval(value * 3600)
        case .minutes(let value):
            return TimeInterval(value * 60)
        case .seconds(let value):
            return TimeInterval(value)
        case .milliseconds(let value):
            return TimeInterval(value) / TimeInterval(MSEC_PER_SEC)
        }
    }
    
    public static func <(lhs: TimerDuration, rhs: TimerDuration) -> Bool {
        return lhs.timeInterval < rhs.timeInterval
    }
}
