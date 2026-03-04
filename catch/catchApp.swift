import SwiftUI
import SwiftData
import CatchCore

@main
struct catchApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authService: AppleAuthService
    @State private var followService: CKFollowService
    @State private var breedClassifier = VisionBreedClassifierService()
    @State private var catSyncService: CKCatSyncService
    @State private var encounterSyncService: CKEncounterSyncService
    @State private var userBrowseService: CKUserBrowseService
    @State private var socialInteractionService: CKSocialInteractionService
    @State private var socialFeedService: CKSocialFeedService
    @State private var toastManager = ToastManager()
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

        let auth = AppleAuthService()
        let follow = CKFollowService()
        let catRepo = CKCatRepository()
        let encRepo = CKEncounterRepository()

        let getUserID: @Sendable () -> String? = { [auth] in
            auth.authState.user?.userIdentifier
        }

        let browseService = CKUserBrowseService(
            cloudKitService: CKCloudKitService(),
            catRepository: catRepo,
            encounterRepository: encRepo,
            followService: follow,
            currentUserIDProvider: getUserID
        )

        _authService = State(initialValue: auth)
        _followService = State(initialValue: follow)
        _catSyncService = State(initialValue: CKCatSyncService(
            catRepository: catRepo,
            encounterRepository: encRepo,
            getUserID: getUserID
        ))
        _encounterSyncService = State(initialValue: CKEncounterSyncService(
            encounterRepository: encRepo,
            getUserID: getUserID
        ))
        _userBrowseService = State(initialValue: browseService)
        _socialInteractionService = State(initialValue: CKSocialInteractionService(
            getCurrentUserID: getUserID,
            cloudKitService: CKCloudKitService()
        ))
        _socialFeedService = State(initialValue: CKSocialFeedService(
            followService: follow,
            userBrowseService: browseService
        ))
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
                    .toastOverlay()
                    .environment(breedClassifier)
                    .environment(authService)
                    .environment(followService)
                    .environment(catSyncService)
                    .environment(encounterSyncService)
                    .environment(userBrowseService)
                    .environment(socialInteractionService)
                    .environment(socialFeedService)
                    .environment(toastManager)
                    .task {
                        await authService.checkCredentialState()
                        #if DEBUG
                        seedDebugData()
                        #endif
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }

    #if DEBUG
    private func seedDebugData() {
        DataSeeder.seedIfEmpty(context: modelContainer.mainContext)
        let fakeUserID = authService.authState.user?.userIdentifier ?? "debug-user"
        followService.seedFakeFollows(currentUserID: fakeUserID)
        userBrowseService.seedFakeUsers()
        socialInteractionService.seedFakeInteractions(encounterRecordNames: [
            "tuong-enc-1", "tuong-enc-2", "tuong-enc-3", "tuong-enc-4",
            "sophi-enc-1", "sophi-enc-2"
        ])
    }
    #endif
}
