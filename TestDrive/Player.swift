//
//  Player.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

enum Player: CaseIterable, Identifiable {
    case computer, user
    
    var id: Int { hashValue }
    
    var symbol: String {
        switch self {
        case .computer:
            "iphone"
        case .user:
            "person.fill"
        }
    }
}
