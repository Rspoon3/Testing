//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestDriveApp: App {
    
    
    let fileStorage = Test()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await fileStorage.getTime()
                }
        }
    }
}
/// A protocol for providing the current date.
public protocol DateProviding {
    /// Returns the current date.
    var now: Date { get }
}

/// Default implementation that always returns the actual current date.
public struct CurrentDateProvider: DateProviding {
    /// Returns the current date each time it's called.
    public var now: Date {
        Date()
    }
    
    public init() {}
}

public final class Test {
    private let dateProvider: any DateProviding
    
    public init(
        dateProvider: DateProviding = CurrentDateProvider()
    ) {
        self.dateProvider = dateProvider
    }
 
    func getTime() async {
        for _ in 0..<5 {
            print(dateProvider.now)
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
