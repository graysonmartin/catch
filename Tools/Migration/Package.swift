// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CatchMigration",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.41.1")
    ],
    targets: [
        .target(
            name: "MigrationLib",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Sources/MigrationLib",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "Migration",
            dependencies: ["MigrationLib"],
            path: "Sources/Migration",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "MigrationTests",
            dependencies: ["MigrationLib"],
            path: "Tests/MigrationTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
