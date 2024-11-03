//
//  FlashableColor.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

import SwiftUI

enum FlashableColor: Int, CaseIterable, Identifiable {
    case red = 1, green, blue, yellow
    
    var id: Int { rawValue }
    
    var color: Color {
        switch self {
        case .red:
            return .red
        case .green:
            return .green
        case .blue:
            return .blue
        case .yellow:
            return .yellow
        }
    }
}
