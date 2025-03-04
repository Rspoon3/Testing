//
//  ColorItem.swift
//  Testing
//
//  Created by Ricky on 3/3/25.
//

import Foundation

struct ColorItem: Identifiable, Equatable {
    let hex: String
    let id: String
    let row: Int
    let col: Int
}
