// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

@preconcurrency import PackageDescription

let package = Package(
    name: "TestDriveHome",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(for: .testDriveHome)
    ],
    dependencies: [
        .sfSymbols,
        .testDriveCore,
        .testDriveApp,
        .testDrivePersistence,
        .vaultFeature,
        .keyFeature,
        .settingsFeature
    ],
    targets: [
        .testDriveHome,
        .unitTests(for: .testDriveHome)
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

    static let testDriveHome: Target = .target(
        name: "TestDriveHome",
        dependencies: [
            .sfSymbols,
            .testDriveCore,
            .testDriveApp,
            .testDrivePersistence,
            .vaultFeature,
            .keyFeature,
            .settingsFeature
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

    static let testDriveApp: Target.Dependency = .product(
        name: "TestDriveApp",
        package: "TestDriveApp"
    )

    static let testDrivePersistence: Target.Dependency = .product(
        name: "TestDrivePersistence",
        package: "TestDrivePersistence"
    )

    static let vaultFeature: Target.Dependency = .product(
        name: "VaultFeature",
        package: "VaultFeature"
    )

    static let keyFeature: Target.Dependency = .product(
        name: "KeyFeature",
        package: "KeyFeature"
    )

    static let settingsFeature: Target.Dependency = .product(
        name: "SettingsFeature",
        package: "SettingsFeature"
    )
}

extension Package.Dependency {

    static let sfSymbols: Package.Dependency = .package(
        url: "https://github.com/Rspoon3/SFSymbols",
        exact: "2.8.1"
    )

    static let testDriveCore: Package.Dependency = .package(
        path: "../TestDriveCore"
    )

    static let testDriveApp: Package.Dependency = .package(
        path: "../TestDriveApp"
    )

    static let testDrivePersistence: Package.Dependency = .package(
        path: "../TestDrivePersistence"
    )

    static let vaultFeature: Package.Dependency = .package(
        path: "../VaultFeature"
    )

    static let keyFeature: Package.Dependency = .package(
        path: "../KeyFeature"
    )

    static let settingsFeature: Package.Dependency = .package(
        path: "../SettingsFeature"
    )
}
