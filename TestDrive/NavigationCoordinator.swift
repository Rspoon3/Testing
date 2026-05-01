//
//  NavigationCoordinator.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import Foundation
import SwiftUI

@MainActor
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    
    private init() {}
    
    func navigate(to destination: NavigationDestination) {
        switch destination {
        case .colorScreen(let colorName):
            navigationPath.append(ColorDestination.color(colorName))
        }
    }
    
    func presentSheet(_ sheet: SheetDestination) {
        presentedSheet = sheet
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}

enum NavigationDestination {
    case colorScreen(String)
}

enum SheetDestination: Identifiable {
    case colorSheet(String)
    
    var id: String {
        switch self {
        case .colorSheet(let color):
            return "colorSheet-\(color)"
        }
    }
}

enum ColorDestination: Hashable {
    case color(String)
}