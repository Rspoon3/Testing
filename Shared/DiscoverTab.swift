//
//  DiscoverTab.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/13/23.
//

import Foundation


enum DiscoverTab: String, CaseIterable, Identifiable {
    case offers, brands
    var id: String { rawValue }
    
    func assetTitle(isSelected: Bool)-> String {
        switch self {
        case .offers:
            return isSelected ? "tag" :"tag.fill"
        case .brands:
            return isSelected ? "trash" :"trash.fill"
        }
    }
}
