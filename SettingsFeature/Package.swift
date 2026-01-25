// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

@preconcurrency import PackageDescription

let package = Package(
    name: "SettingsFeature",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(for: .settingsFeature)
    ],
    dependencies: [
        .sfSymbols,
        .testDriveCore,
        .testDrivePersistence
    ],
    targets: [
        .settingsFeature,
        .unitTests(for: .settingsFeature)
    ]
)

// MARK: - Products

extension Product {

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

    static func target(_ target: Target) -> Target.Dependency {
        .target(name: target.name)
    }
}

extension Target {

    static let settingsFeature: Target = .target(
        name: "SettingsFeature",
        dependencies: [
            .sfSymbols,
            .testDriveCore,
            .testDrivePersistence
        ]
    )

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

    static let sfSymbols: Target.Dependency = .product(
        name: "SFSymbols",
        package: "SFSymbols"
    )

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

    static let sfSymbols: Package.Dependency = .package(
        url: "https://github.com/Rspoon3/SFSymbols",
        exact: "3.0.0"
    )

    static let testDriveCore: Package.Dependency = .package(
        path: "../TestDriveCore"
    )

    static let testDrivePersistence: Package.Dependency = .package(
        path: "../TestDrivePersistence"
    )
}
