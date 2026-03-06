// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CatchCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CatchCore", targets: ["CatchCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.41.1")
    ],
    targets: [
        .target(
            name: "CatchCore",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Sources/CatchCore",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "CatchCoreTests",
            dependencies: ["CatchCore"],
            path: "Tests/CatchCoreTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
