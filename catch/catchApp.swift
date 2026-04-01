import SwiftUI
import UserNotifications
import CatchCore

@main
struct catchApp: App {
    @UIApplicationDelegateAdaptor(CatchAppDelegate.self) private var appDelegate
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.hasCompletedProfileSetup) private var hasCompletedProfileSetup = false
    @AppStorage(AppStorageKeys.hasCompletedNewUserWalkthrough) private var hasCompletedNewUserWalkthrough = false
    @AppStorage(AppStorageKeys.hasCompletedUnifiedOnboarding) private var hasCompletedUnifiedOnboarding = false
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
    @State private var feedDataService: FeedDataService
    @State private var reportService: SupabaseReportService
    @State private var blockService: SupabaseBlockService
    @State private var suggestedPeopleService: SuggestedPeopleService
    @StateObject private var appRouter: AppRouter
    @State private var deviceTokenService: DeviceTokenService?
    @State private var notificationDelegate: NotificationDelegate?
    @State private var inAppNotificationService: SupabaseInAppNotificationService

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
        let reportRepo = DefaultSupabaseReportRepository(clientProvider: provider)
        let blockRepo = DefaultBlockRepository(clientProvider: provider)
        let hiddenEncounterRepo = DefaultHiddenEncounterRepository(clientProvider: provider)
        let feedRepo = DefaultSupabaseFeedRepository(clientProvider: provider)
        let assets = DefaultSupabaseAssetService(clientProvider: provider)

        let catRepoAdapter = SupabaseCatRepositoryAdapter(repository: catRepo)
        let encRepoAdapter = SupabaseEncounterRepositoryAdapter(repository: encRepo)

        let follow = SupabaseFollowService(
            repository: followRepo,
            clientProvider: provider,
            profileRepository: profileRepo
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

        let report = SupabaseReportService(
            repository: reportRepo,
            hiddenEncounterRepository: hiddenEncounterRepo,
            getCurrentUserID: getUserID
        )

        let block = SupabaseBlockService(
            repository: blockRepo,
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
        _reportService = State(initialValue: report)
        _blockService = State(initialValue: block)
        _socialFeedService = State(initialValue: socialFeed)
        _profileSyncService = State(initialValue: ProfileSyncService(
            profileRepository: profileRepo,
            assetService: assets
        ))
        let catData = CatDataService(
            catRepository: catRepo,
            encounterRepository: encRepo,
            assetService: assets,
            getUserID: getUserID
        )
        let encounterData = EncounterDataService(
            encounterRepository: encRepo,
            assetService: assets,
            getUserID: getUserID
        )
        _catDataService = State(initialValue: catData)
        _encounterDataService = State(initialValue: encounterData)
        _appRouter = StateObject(wrappedValue: AppRouter(
            encounterDataService: encounterData,
            catDataService: catData
        ))
        _feedDataService = State(initialValue: FeedDataService(
            encounterRepository: encRepo,
            getUserID: getUserID
        ))
        _suggestedPeopleService = State(initialValue: SuggestedPeopleService(
            profileRepository: profileRepo,
            catRepository: catRepoAdapter,
            currentUserIDProvider: getUserID,
            followedIDsProvider: { [follow] in
                Set(follow.following.map(\.followeeID))
            }
        ))
        _deviceTokenService = State(initialValue: DeviceTokenService(
            clientProvider: provider,
            getCurrentUserID: getUserID
        ))
        _inAppNotificationService = State(initialValue: SupabaseInAppNotificationService(
            clientProvider: provider,
            getCurrentUserID: getUserID
        ))
    }

    var body: some Scene {
        WindowGroup {
            mainContent
                .onAppear {
                    installToastWindow()
                    setupNotificationDelegate()
                }
                .onChange(of: authService.authState) { oldState, newState in
                    if oldState == .unknown, newState.isSignedIn, !hasCompletedProfileSetup {
                        isCheckingProfile = true
                        Task { await checkExistingProfile() }
                    }
                    if newState == .signedOut {
                        hasCompletedProfileSetup = false
                        Task { await deviceTokenService?.clearToken() }
                    }
                    if !oldState.isSignedIn, newState.isSignedIn {
                        Task { await deviceTokenService?.requestPermissionIfNeeded() }
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

    private func setupNotificationDelegate() {
        guard let tokenService = deviceTokenService, notificationDelegate == nil else { return }
        let delegate = NotificationDelegate(
            tokenService: tokenService,
            router: appRouter
        )
        notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
        appDelegate.notificationDelegate = delegate
    }

    /// Existing users who finished the old onboarding + walkthrough flow skip the unified flow.
    private var hasLegacyOnboardingComplete: Bool {
        hasCompletedOnboarding && hasCompletedProfileSetup
    }

    /// If the user is already signed in with a profile, skip straight to post-auth steps.
    private var onboardingStartPhase: UnifiedOnboardingView.Phase {
        if hasCompletedProfileSetup && authService.authState.isSignedIn {
            return .postAuth(0)
        }
        return .featureTour
    }

    @ViewBuilder
    private var mainContent: some View {
        if !hasCompletedUnifiedOnboarding && !hasLegacyOnboardingComplete {
            UnifiedOnboardingView(startPhase: onboardingStartPhase) {
                hasCompletedUnifiedOnboarding = true
                hasCompletedProfileSetup = true
                hasCompletedOnboarding = true
            }
            .environment(authService)
            .environment(profileSyncService)
            .environment(toastManager)
            .environment(followService)
            .environment(suggestedPeopleService)
        } else if authService.authState == .unknown || isCheckingProfile {
            PawLoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CatchTheme.background)
        } else if !authService.authState.isSignedIn {
            ProfileSetupView { isNewUser in
                hasCompletedProfileSetup = true
            }
            .environment(authService)
            .environment(profileSyncService)
            .environment(toastManager)
        } else if !hasCompletedProfileSetup {
            ProfileSetupView { isNewUser in
                hasCompletedProfileSetup = true
            }
            .environment(authService)
            .environment(profileSyncService)
            .environment(toastManager)
        } else {
            ContentView()
                .environmentObject(appRouter)
                .environment(breedClassifier)
                .environment(authService)
                .environment(followService)
                .environment(userBrowseService)
                .environment(socialInteractionService)
                .environment(reportService)
                .environment(blockService)
                .environment(socialFeedService)
                .environment(profileSyncService)
                .environment(supabaseProvider)
                .environment(locationSearchService)
                .environment(toastManager)
                .environment(catDataService)
                .environment(encounterDataService)
                .environment(feedDataService)
                .environment(suggestedPeopleService)
                .environment(inAppNotificationService)
                .task {
                    await authService.refreshSessionIfNeeded()
                    async let blocks: Void = { try? await blockService.loadBlocks() }()
                    async let hidden: Void = { try? await reportService.loadHiddenEncounters() }()
                    _ = await (blocks, hidden)
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
