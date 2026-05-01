//
//  FactoryEnvironmentKey.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import SwiftUI

/// Environment key for accessing the RootFactory throughout the SwiftUI view hierarchy.
private struct FactoryEnvironmentKey: EnvironmentKey {
    static let defaultValue: RootFactory = RootFactory()
}

extension EnvironmentValues {
    /// Provides access to the root factory via the SwiftUI environment.
    var factory: RootFactory {
        get { self[FactoryEnvironmentKey.self] }
        set { self[FactoryEnvironmentKey.self] = newValue }
    }
}
