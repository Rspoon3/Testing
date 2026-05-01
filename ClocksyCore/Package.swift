// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

@preconcurrency import PackageDescription

let package = Package(
    name: "ClocksyCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(for: .clocksyKit),
    ],
    dependencies: [
        .swiftTools
    ],
    targets: [
        .clocksyKit
    ]
)

// MARK: - Products

extension Product {
    
    // MARK: Library
    
    /// Returns a library product for the specified target.
    ///
    /// - Parameters:
    ///   - target: The target.
    ///   - type: The optional type of the library that’s used to determine how
    ///     to link to the library. Omit this parameter so Swift Package Manager
    ///     can choose between static or dynamic linking (recommended). If you
    ///     don’t support both linkage types, use `.static` or `.dynamic` for
    ///     this parameter.
    /// - Returns: A library product for the specified target.
    static func library(
        for target: Target,
        type: Library.LibraryType? = nil
    ) -> Product {
        .library(
            name: target.name,
            type: type,
            targets: [target.name]
        )
    }
}

// MARK: - Targets

extension Target.Dependency {
    // MARK: Target
    
    /// Returns a target dependency.
    ///
    /// - Parameter target: The target.
    /// - Returns: A target dependency.
    static func target(_ target: Target) -> Target.Dependency {
        .target(name: target.name)
    }
}

extension Target {
    
    static let clocksyKit: Target = .target(
        name: "ClocksyKit",
        dependencies: [
            .swiftTools
        ]
    )
    
    // MARK: Unit Tests

    static func unitTests(
        for target: Target,
        additionalDependencies: [Target.Dependency] = [],
        resources: [Resource] = []
    ) -> Target {
        .testTarget(
            name: "\(target.name)Tests",
            dependencies: [.target(target)] + additionalDependencies,
            resources: resources
        )
    }
}

extension Target.Dependency {
    
    static let swiftTools: Target.Dependency = .product(
        name: "SwiftTools",
        package: "SwiftTools"
    )
}

extension Package.Dependency {
    
    static let swiftTools: Package.Dependency = .package(
        url: "https://github.com/Rspoon3/SwiftTools",
        exact: "2.2.4"
    )
}
