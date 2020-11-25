//
//  Steps.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/24/20.
//

import SwiftUI

struct Steps: Identifiable{
    let id = UUID()
    let date: Date
    let value: Int
    
    var formattedDate: String{
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("M/dd")
        return formatter.string(from: date)
    }
}
