import SwiftUI
import CatchCore

@main
struct catchApp: App {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.hasCompletedProfileSetup) private var hasCompletedProfileSetup = false
    @State private var authService: SupabaseAuthService
    @State private var followService: SupabaseFollowService
    @State private var breedClassifier = VisionBreedClassifierService()
    @State private var userBrowseService: SupabaseUserBrowseService
    @State private var socialInteractionService: SupabaseSocialInteractionService
    @State private var socialFeedService: DefaultSocialFeedService
    @State private var profileSyncService: ProfileSyncService
    @State private var supabaseProvider: SupabaseClientProvider
    @State private var locationSearchService = MKLocationSearchService()
    @State private var toastManager = ToastManager()
    @State private var catDataService: CatDataService
    @State private var encounterDataService: EncounterDataService
    @State private var feedDataService: FeedDataService

    init() {
        #if DEBUG
        SupabaseConfig.current = .development
        #endif

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
        let assets = DefaultSupabaseAssetService(clientProvider: provider)

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
        _userBrowseService = State(initialValue: browseService)
        _socialInteractionService = State(initialValue: socialInteraction)
        _socialFeedService = State(initialValue: socialFeed)
        _profileSyncService = State(initialValue: ProfileSyncService(
            profileRepository: profileRepo,
            assetService: assets
        ))
        _catDataService = State(initialValue: CatDataService(
            catRepository: catRepo,
            encounterRepository: encRepo,
            assetService: assets,
            getUserID: getUserID
        ))
        _encounterDataService = State(initialValue: EncounterDataService(
            encounterRepository: encRepo,
            assetService: assets,
            getUserID: getUserID
        ))
        _feedDataService = State(initialValue: FeedDataService(
            encounterRepository: encRepo,
            getUserID: getUserID
        ))
    }

    var body: some Scene {
        WindowGroup {
            mainContent
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else if authService.authState == .unknown {
            PawLoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CatchTheme.background)
        } else if !authService.authState.isSignedIn {
            ProfileSetupView {
                hasCompletedProfileSetup = true
            }
            .environment(authService)
            .environment(profileSyncService)
            .environment(toastManager)
        } else if !hasCompletedProfileSetup {
            ProfileSetupView {
                hasCompletedProfileSetup = true
            }
            .environment(authService)
            .environment(profileSyncService)
            .environment(toastManager)
        } else {
            ContentView()
                .toastOverlay()
                .environment(breedClassifier)
                .environment(authService)
                .environment(followService)
                .environment(userBrowseService)
                .environment(socialInteractionService)
                .environment(socialFeedService)
                .environment(profileSyncService)
                .environment(supabaseProvider)
                .environment(locationSearchService)
                .environment(toastManager)
                .environment(catDataService)
                .environment(encounterDataService)
                .environment(feedDataService)
                .task {
                    await authService.refreshSessionIfNeeded()
                }
                .onChange(of: authService.authState) { _, newState in
                    if newState == .signedOut {
                        hasCompletedProfileSetup = false
                    }
                }
        }
    }
}
