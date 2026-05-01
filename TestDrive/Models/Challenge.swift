//
//  Challenge.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/24/20.
//

import SwiftUI

struct Challenge: Hashable{
    let title: String
    let startDate: Date
    let endDate: Date
    
    var formattedDates: String{
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("M/dd h:mm:ss a")
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }
}
