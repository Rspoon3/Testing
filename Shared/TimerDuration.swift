//
//  TimerDuration.swift
//  
//
//  Created by Richard Witherspoon on 12/13/23.
//

import Foundation


extension Duration {
    public var timeInterval: TimeInterval {
        TimeInterval(components.seconds)
    }
    
    public static func minutes(_ minutes: Double) -> Duration {
        return .seconds(minutes * 60)
    }
    
    public static func hours(_ hours: Double) -> Duration {
        return .seconds(hours * 3_600)
    }
    
    public static func days(_ days: Double) -> Duration {
        return .seconds(days * 86_400)
    }
    
    public static func weeks(_ weeks: Double) -> Duration {
        return .seconds(weeks * 604_800)
    }
}
