//
//  MuscleGroup.swift
//  Testing
//
//  Created by Richard Witherspoon on 1/13/24.
//

import SwiftUI
import SwiftData
import SwiftUI

@Model
public class MuscleGroup {
    public var title: String
    private(set) var creationDate: Date
    

    init(title: String, uiColor: UIColor) {
        self.title = title
        self.creationDate = .now
    }
}
struct ColorComponents: Codable {
    let red: Float
    let green: Float
    let blue: Float

    var color: Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue))
    }

    static func fromColor(_ color: Color) -> ColorComponents {
        let resolved = color.resolve(in: EnvironmentValues())
        return ColorComponents(
            red: resolved.red,
            green: resolved.green,
            blue: resolved.blue
        )
    }
}
