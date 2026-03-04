import SwiftUI
import SwiftData
import CatchCore

@main
struct catchApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authService = AppleAuthService()
    @State private var followService = CKFollowService()
    @State private var breedClassifier = VisionBreedClassifierService()
    @State private var catSyncService: CKCatSyncService?
    @State private var encounterSyncService: CKEncounterSyncService?
    @State private var userBrowseService: CKUserBrowseService?
    @State private var socialInteractionService: CKSocialInteractionService?
    @State private var socialFeedService: CKSocialFeedService?
    @State private var toastManager = ToastManager()
    @State private var databaseState: DatabaseState

    init() {
        _databaseState = State(initialValue: DatabaseState())
    }

    var body: some Scene {
        WindowGroup {
            switch databaseState.status {
            case .ready(let container):
                mainContent(container: container)
                    .modelContainer(container)
            case .failed(let errorDescription):
                DatabaseRecoveryView(
                    errorMessage: errorDescription,
                    onRetry: { databaseState.retry() },
                    onReset: { databaseState.resetAndRetry() }
                )
            }
        }
    }

    @ViewBuilder
    private func mainContent(container: ModelContainer) -> some View {
        if hasCompletedOnboarding {
            ContentView()
                .environment(breedClassifier)
                .environment(authService)
                .environment(followService)
                .environment(catSyncService)
                .environment(encounterSyncService)
                .environment(userBrowseService)
                .environment(socialInteractionService)
                .environment(socialFeedService)
                .environment(toastManager)
                .toastOverlay()
                .task {
                    await authService.checkCredentialState()
                    if catSyncService == nil {
                        initializeServices(container: container)
                    }
                }
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }

    private func initializeServices(container: ModelContainer) {
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
        let browseService = CKUserBrowseService(
            cloudKitService: CKCloudKitService(),
            catRepository: catRepo,
            encounterRepository: encRepo,
            followService: followService,
            currentUserIDProvider: getUserID
        )
        userBrowseService = browseService
        socialInteractionService = CKSocialInteractionService(
            getCurrentUserID: getUserID,
            cloudKitService: CKCloudKitService()
        )
        socialFeedService = CKSocialFeedService(
            followService: followService,
            userBrowseService: browseService
        )

        #if DEBUG
        DataSeeder.seedIfEmpty(context: container.mainContext)
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
