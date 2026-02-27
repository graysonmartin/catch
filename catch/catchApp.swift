import SwiftUI
import SwiftData
import CatchCore

@main
struct catchApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authService = AppleAuthService()
    @State private var followService = CKFollowService()
    @State private var breedClassifier = VisionBreedClassifierService()
    @State private var catPhotoValidator = VisionCatPhotoValidationService()
    @State private var catSyncService: CKCatSyncService?
    @State private var encounterSyncService: CKEncounterSyncService?
    @State private var userBrowseService: CKUserBrowseService?
    @State private var socialInteractionService: CKSocialInteractionService?
    @State private var socialFeedService: CKSocialFeedService?
    let modelContainer: ModelContainer

    init() {
        let schema = Schema(versionedSchema: CatchSchemaV6.self)
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: CatchMigrationPlan.self,
                configurations: config
            )
        } catch {
            #if DEBUG
            Self.deleteStoreFiles(for: config)
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: CatchMigrationPlan.self,
                    configurations: config
                )
                print("[catch] wiped stale store and recovered")
            } catch {
                fatalError("Failed to create ModelContainer after wipe: \(error)")
            }
            #else
            fatalError("Failed to create ModelContainer: \(error)") 
            #endif
        }
    }

    #if DEBUG
    private static func deleteStoreFiles(for config: ModelConfiguration) {
        let url = config.url
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let path = suffix.isEmpty ? url : URL(fileURLWithPath: url.path + suffix)
            try? fm.removeItem(at: path)
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(breedClassifier)
                    .environment(catPhotoValidator)
                    .environment(authService)
                    .environment(followService)
                    .environment(catSyncService)
                    .environment(encounterSyncService)
                    .environment(userBrowseService)
                    .environment(socialInteractionService)
                    .environment(socialFeedService)
                    .task {
                        await authService.checkCredentialState()
                        if catSyncService == nil {
                            let catRepo = CKCatRepository()
                            let encRepo = CKEncounterRepository()
                            let getUserID: () -> String? = { [authService] in
                                authService.authState.user?.userIdentifier
                            }
                            catSyncService = CKCatSyncService(
                                catRepository: catRepo,
                                encounterRepository: encRepo,
                                getUserID: getUserID
                            )
                            encounterSyncService = CKEncounterSyncService(
                                encounterRepository: encRepo,
                                getUserID: getUserID
                            )
                            userBrowseService = CKUserBrowseService(
                                cloudKitService: CKCloudKitService(),
                                catRepository: catRepo,
                                encounterRepository: encRepo,
                                followService: followService,
                                currentUserIDProvider: getUserID
                            )
                            socialInteractionService = CKSocialInteractionService(
                                getCurrentUserID: getUserID
                            )
                            socialFeedService = CKSocialFeedService(
                                followService: followService,
                                userBrowseService: userBrowseService!
                            )

                            #if DEBUG
                            DataSeeder.seedIfEmpty(context: modelContainer.mainContext)
                            let fakeUserID = authService.authState.user?.userIdentifier ?? "debug-user"
                            followService.seedFakeFollows(currentUserID: fakeUserID)
                            userBrowseService?.seedFakeUsers()
                            socialInteractionService?.seedFakeInteractions(encounterRecordNames: [
                                "tuong-enc-1", "tuong-enc-2", "tuong-enc-3", "tuong-enc-4",
                                "sophi-enc-1", "sophi-enc-2"
                            ])
                            #endif
                        }
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }
}
