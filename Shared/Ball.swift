//
//  Ball.swift
//  Testing
//
//  Created by Ricky on 3/28/25.
//


import SwiftUI

struct Ball: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var isBlue: Bool
}
