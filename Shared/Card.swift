//
//  Card.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI
import UIImageColors

struct Card: Identifiable {
    let id = UUID()
    let number: Int
    var offset: CGSize = .zero
    let imageNumber: Int
    let isPrime: Bool
    let colors: UIImageColors?
    
    var color: Color {
        guard let c = colors?.primary else { return .white }
        return Color(c)
    }
    
    init(id: Int) {
        self.number = id
        self.imageNumber = (id % 19) + 1
        self.colors = nil //UIImage(named: "numbers\(imageNumber)")?.getColors(quality: .low)
        
        guard id > 1 else {
            isPrime = false
            return
        }
        
        var temp = true
        for i in 2..<Int(sqrt(Double(id))) + 1 {
            if id % i == 0 { temp = false }
        }
        
        isPrime = temp
    }
}
