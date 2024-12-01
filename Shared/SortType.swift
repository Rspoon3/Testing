//
//  SortType.swift
//  Testing (iOS)
//
//  Created by Ricky on 11/30/24.
//

import Foundation

enum SortType: Int, CaseIterable, Identifiable {
    case title = 0
    case year = 1
    case number = 2
    case collected = 3
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .title: return "Title"
        case .year: return "Year Founded"
        case .number: return "State Number"
        case .collected: return "Collected"
        }
    }
    
    var sortComparator: [SortDescriptor<USState>] {
        switch self {
        case .title:
            [SortDescriptor(\USState.title, order: .forward)]
        case .year:
            [
                SortDescriptor(\USState.yearFounded, order: .forward),
                SortDescriptor(\USState.title, order: .forward)
            ]
        case .number:
            [
                SortDescriptor(\USState.stateNumber, order: .forward),
                SortDescriptor(\USState.title, order: .forward)
            ]
        case .collected:
            [
                SortDescriptor(\USState.funDescription, order: .forward),
                SortDescriptor(\USState.title, order: .forward)
            ]
        }
    }
}



