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
    private var colorComponents: ColorComponents
    public var color: Color { colorComponents.color }

    init(title: String, color: Color) {
        self.title = title
        self.creationDate = .now
        self.colorComponents = .init(color: color)
    }
}
