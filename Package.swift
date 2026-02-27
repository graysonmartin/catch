// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CatchCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "CatchCore", targets: ["CatchCore"])
    ],
    targets: [
        .target(
            name: "CatchCore",
            path: "catch",
            sources: [
                // Models
                "Models/Location.swift",
                "Models/VisibilitySettings.swift",

                // Theme (subset needed by CatchCore types)
                "Theme/CatchStrings.swift",

                // Auth
                "Services/Auth/AuthState.swift",
                "Services/Auth/AuthService.swift",

                // BreedClassifier
                "Services/BreedClassifier/BreedPrediction.swift",
                "Services/BreedClassifier/BreedLabelMapper.swift",
                "Services/BreedClassifier/BreedClassifierService.swift",

                // CloudKit
                "Services/CloudKit/CloudKitService.swift",
                "Services/CloudKit/CKCloudKitService.swift",

                // CloudSync
                "Services/CloudSync/CloudSyncError.swift",
                "Services/CloudSync/CloudCat.swift",
                "Services/CloudSync/CloudEncounter.swift",
                "Services/CloudSync/CatSyncPayload.swift",
                "Services/CloudSync/EncounterSyncPayload.swift",
                "Services/CloudSync/CatRecordMapper.swift",
                "Services/CloudSync/EncounterRecordMapper.swift",
                "Services/CloudSync/CatRepository.swift",
                "Services/CloudSync/EncounterRepository.swift",

                // Follow
                "Services/Follow/Follow.swift",
                "Services/Follow/FollowStatus.swift",
                "Services/Follow/FollowServiceError.swift",
                "Services/Follow/FollowService.swift",
                "Services/Follow/CKFollowService.swift",
                "Services/Follow/CKFollowServiceSubscription.swift",

                // Social
                "Services/Social/EncounterComment.swift",
                "Services/Social/EncounterLike.swift",
                "Services/Social/CommentRecordMapper.swift",
                "Services/Social/LikeRecordMapper.swift",
                "Services/Social/SocialInteractionError.swift",
                "Services/Social/SocialInteractionService.swift",
                "Services/Social/CKSocialInteractionService.swift",

                // UserBrowse
                "Services/UserBrowse/UserBrowseService.swift",
                "Services/UserBrowse/UserBrowseData.swift",
                "Services/UserBrowse/UserBrowseError.swift",
                "Services/UserBrowse/CKUserBrowseService.swift",

                // Username
                "Services/Username/UsernameValidator.swift",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "CatchCoreTests",
            dependencies: ["CatchCore"],
            path: "CatchCoreTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
