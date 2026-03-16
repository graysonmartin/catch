import SwiftUI
import SwiftData
import CatchCore

@main
struct catchApp: App {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.hasCompletedProfileSetup) private var hasCompletedProfileSetup = false
    @AppStorage(AppStorageKeys.hasAttemptedRestore) private var hasAttemptedRestore = false
    @State private var authService: SupabaseAuthService
    @State private var followService: SupabaseFollowService
    @State private var breedClassifier = VisionBreedClassifierService()
    @State private var catSyncService: DefaultCatSyncService
    @State private var encounterSyncService: DefaultEncounterSyncService
    @State private var userBrowseService: SupabaseUserBrowseService
    @State private var socialInteractionService: SupabaseSocialInteractionService
    @State private var socialFeedService: DefaultSocialFeedService
    @State private var profileSyncService: ProfileSyncService
    @State private var restoreService: DefaultRestoreService
    @State private var supabaseProvider: SupabaseClientProvider
    @State private var locationSearchService = MKLocationSearchService()
    @State private var toastManager = ToastManager()
    @State private var databaseState: DatabaseState

    init() {
        _databaseState = State(initialValue: DatabaseState())

        let provider = SupabaseClientProvider()
        let auth = SupabaseAuthService(clientProvider: provider)

        let getUserID: @Sendable () -> String? = { [auth] in
            auth.authState.user?.id
        }

        let profileRepo = DefaultSupabaseProfileRepository(clientProvider: provider)
        let catRepo = DefaultSupabaseCatRepository(clientProvider: provider)
        let encRepo = DefaultSupabaseEncounterRepository(clientProvider: provider)
        let followRepo = DefaultSupabaseFollowRepository(clientProvider: provider)
        let socialRepo = DefaultSupabaseSocialRepository(clientProvider: provider)
        let feedRepo = DefaultSupabaseFeedRepository(clientProvider: provider)

        let catRepoAdapter = SupabaseCatRepositoryAdapter(repository: catRepo)
        let encRepoAdapter = SupabaseEncounterRepositoryAdapter(repository: encRepo)

        let follow = SupabaseFollowService(
            repository: followRepo,
            clientProvider: provider
        )

        let browseService = SupabaseUserBrowseService(
            profileRepository: profileRepo,
            catRepository: catRepoAdapter,
            encounterRepository: encRepoAdapter,
            followService: follow,
            currentUserIDProvider: getUserID
        )

        let socialInteraction = SupabaseSocialInteractionService(
            repository: socialRepo,
            clientProvider: provider,
            getCurrentUserID: getUserID
        )

        let socialFeed = DefaultSocialFeedService(
            repository: feedRepo,
            followService: follow
        )

        _supabaseProvider = State(initialValue: provider)
        _authService = State(initialValue: auth)
        _followService = State(initialValue: follow)
        _catSyncService = State(initialValue: DefaultCatSyncService(
            catRepository: catRepoAdapter,
            encounterRepository: encRepoAdapter,
            getUserID: getUserID
        ))
        _encounterSyncService = State(initialValue: DefaultEncounterSyncService(
            encounterRepository: encRepoAdapter,
            getUserID: getUserID
        ))
        _userBrowseService = State(initialValue: browseService)
        _socialInteractionService = State(initialValue: socialInteraction)
        _socialFeedService = State(initialValue: socialFeed)
        _profileSyncService = State(initialValue: ProfileSyncService(
            profileRepository: profileRepo
        ))
        _restoreService = State(initialValue: DefaultRestoreService(
            catRepository: catRepoAdapter,
            encounterRepository: encRepoAdapter
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
    }
    #endif
}
