// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

@preconcurrency import PackageDescription

let package = Package(
    name: "TestDriveApp",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(for: .testDriveApp)
    ],
    dependencies: [
        .testDriveCore,
        .testDrivePersistence
    ],
    targets: [
        .testDriveApp,
        .unitTests(for: .testDriveApp)
    ]
)

// MARK: - Products

extension Product {

    /// Returns a library product for the specified target.
    ///
    /// - Parameters:
    ///   - target: The target.
    ///   - type: The optional type of the library that's used to determine how
    ///     to link to the library. Omit this parameter so Swift Package Manager
    ///     can choose between static or dynamic linking (recommended).
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

    /// Returns a target dependency.
    ///
    /// - Parameter target: The target.
    /// - Returns: A target dependency.
    static func target(_ target: Target) -> Target.Dependency {
        .target(name: target.name)
    }
}

extension Target {

    static let testDriveApp: Target = .target(
        name: "TestDriveApp",
        dependencies: [
            .testDriveCore,
            .testDrivePersistence
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

// MARK: - Dependencies

extension Target.Dependency {

    static let testDriveCore: Target.Dependency = .product(
        name: "TestDriveCore",
        package: "TestDriveCore"
    )

    static let testDrivePersistence: Target.Dependency = .product(
        name: "TestDrivePersistence",
        package: "TestDrivePersistence"
    )
}

extension Package.Dependency {

    static let testDriveCore: Package.Dependency = .package(
        path: "../TestDriveCore"
    )

    static let testDrivePersistence: Package.Dependency = .package(
        path: "../TestDrivePersistence"
    )
}
