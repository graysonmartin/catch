import SwiftUI
import CatchCore

@main
struct catchApp: App {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.hasCompletedProfileSetup) private var hasCompletedProfileSetup = false
    @State private var isCheckingProfile = false
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
    @State private var toastWindow = ToastWindow()
    @State private var catDataService: CatDataService
    @State private var encounterDataService: EncounterDataService

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
    }

    var body: some Scene {
        WindowGroup {
            mainContent
                .onAppear {
                    installToastWindow()
                }
                .onChange(of: authService.authState) { oldState, newState in
                    if oldState == .unknown, newState.isSignedIn, !hasCompletedProfileSetup {
                        isCheckingProfile = true
                        Task { await checkExistingProfile() }
                    }
                    if newState == .signedOut {
                        hasCompletedProfileSetup = false
                    }
                }
        }
    }

    private func installToastWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        toastWindow.install(in: windowScene, toastManager: toastManager)
    }

    @ViewBuilder
    private var mainContent: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else if authService.authState == .unknown || isCheckingProfile {
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
                .task {
                    await authService.refreshSessionIfNeeded()
                }
        }
    }

    private func checkExistingProfile() async {
        guard let userID = authService.authState.user?.id else {
            isCheckingProfile = false
            return
        }

        do {
            let profile = try await profileSyncService.fetchProfile(userID: userID)
            if profile != nil {
                hasCompletedProfileSetup = true
            }
        } catch {
            // Profile check failed — fall through to ProfileSetupView
        }

        isCheckingProfile = false
    }
}
