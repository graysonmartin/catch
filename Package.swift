// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CatchCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CatchCore", targets: ["CatchCore"])
    ],
    targets: [
        .target(
            name: "CatchCore",
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
