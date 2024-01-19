//
//  ColorComponents.swift
//  Testing
//
//  Created by Richard Witherspoon on 1/18/24.
//

import SwiftUI

public struct ColorComponents: Codable {
    private let red: Double
    private let green: Double
    private let blue: Double
    private let opacity: Double

    var color: Color {
        Color(
            red: red,
            green: green,
            blue: blue,
            opacity: opacity
        )
    }
    
    init(color: Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        red = Double(resolved.red)
        green =  Double(resolved.green)
        blue =  Double(resolved.blue)
        opacity =  Double(resolved.opacity)
    }
}
