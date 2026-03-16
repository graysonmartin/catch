import SwiftUI
import SwiftData
import CatchCore

@main
struct catchApp: App {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.hasCompletedProfileSetup) private var hasCompletedProfileSetup = false
    @AppStorage(AppStorageKeys.hasAttemptedRestore) private var hasAttemptedRestore = false
    @State private var authService: SupabaseAuthService
    @State private var followService: CKFollowService
    @State private var breedClassifier = VisionBreedClassifierService()
    @State private var catSyncService: CKCatSyncService
    @State private var encounterSyncService: CKEncounterSyncService
    @State private var userBrowseService: CKUserBrowseService
    @State private var socialInteractionService: CKSocialInteractionService
    @State private var socialFeedService: CKSocialFeedService
    @State private var profileSyncService: ProfileSyncService
    @State private var restoreService: CKCloudKitRestoreService
    @State private var supabaseProvider: SupabaseClientProvider
    @State private var locationSearchService = MKLocationSearchService()
    @State private var toastManager = ToastManager()
    @State private var databaseState: DatabaseState

    init() {
        _databaseState = State(initialValue: DatabaseState())

        let provider = SupabaseClientProvider()
        let auth = SupabaseAuthService(clientProvider: provider)
        let follow = CKFollowService()
        let catRepo = CKCatRepository()
        let encRepo = CKEncounterRepository()

        let getUserID: @Sendable () -> String? = { [auth] in
            auth.authState.user?.id
        }

        let browseService = CKUserBrowseService(
            cloudKitService: CKCloudKitService(),
            catRepository: catRepo,
            encounterRepository: encRepo,
            followService: follow,
            currentUserIDProvider: getUserID
        )

        let profileRepo = DefaultSupabaseProfileRepository(clientProvider: provider)

        _supabaseProvider = State(initialValue: provider)
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
        _profileSyncService = State(initialValue: ProfileSyncService(
            profileRepository: profileRepo
        ))
        _restoreService = State(initialValue: CKCloudKitRestoreService(
            catRepository: catRepo,
            encounterRepository: encRepo,
            cloudKitService: CKCloudKitService()
        ))
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
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else if !hasCompletedProfileSetup {
            ProfileSetupView {
                hasCompletedProfileSetup = true
            }
            .environment(authService)
            .environment(profileSyncService)
            .environment(toastManager)
        } else if !hasAttemptedRestore {
            DataRestoreView {
                hasAttemptedRestore = true
            }
            .toastOverlay()
            .environment(authService)
            .environment(restoreService)
            .environment(toastManager)
        } else {
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
                .environment(profileSyncService)
                .environment(supabaseProvider)
                .environment(locationSearchService)
                .environment(toastManager)
                .task {
                    await authService.refreshSessionIfNeeded()
                    #if DEBUG
                    seedDebugData(context: container.mainContext)
                    #endif
                }
        }
    }

    #if DEBUG
    private func seedDebugData(context: ModelContext) {
        DataSeeder.seedIfEmpty(context: context)
        let fakeUserID = authService.authState.user?.id ?? "debug-user"
        followService.seedFakeFollows(currentUserID: fakeUserID)
        userBrowseService.seedFakeUsers()
        socialInteractionService.seedFakeInteractions(encounterRecordNames: [
            "tuong-enc-1", "tuong-enc-2", "tuong-enc-3", "tuong-enc-4",
            "sophi-enc-1", "sophi-enc-2"
        ])
    }
    #endif
}
