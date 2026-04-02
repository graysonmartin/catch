import SwiftUI
import CatchCore

struct ContentView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @Environment(SupabaseFollowService.self) private var followService
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(CatDataService.self) private var catDataService
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var selectedTab = 0
    @State private var feedScrollToTop = false

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(scrollToTop: $feedScrollToTop)
                .tabItem {
                    Label(CatchStrings.Tabs.feed, systemImage: "pawprint.fill")
                }
                .tag(0)

            AddEncounterView(selectedTab: $selectedTab, feedScrollToTop: $feedScrollToTop)
                .tabItem {
                    Label(CatchStrings.Tabs.log, systemImage: "plus.circle.fill")
                }
                .tag(1)

            CatMapView(selectedTab: $selectedTab)
                .tabItem {
                    Label(CatchStrings.Tabs.map, systemImage: "map.fill")
                }
                .tag(2)

            ProfileView(selectedTab: $selectedTab)
                .tabItem {
                    Label(CatchStrings.Tabs.profile, systemImage: "person.crop.circle")
                }
                .tag(3)
                .badge(followService.pendingRequests.count)
        }
        .safeAreaInset(edge: .top) {
            if !networkMonitor.isConnected {
                OfflineBanner()
            }
        }
        .tint(CatchTheme.primary)
        .onAppear {
            appRouter.markReady()
        }
        .onChange(of: appRouter.activeTab) { _, newTab in
            guard let newTab else { return }
            selectedTab = newTab.rawValue
        }
        .onChange(of: appRouter.pendingRoute) { _, route in
            guard let route else { return }
            Task { await appRouter.handleRoute(route) }
        }
        .sheet(item: $appRouter.routedEncounterDetail) { detail in
            EncounterDetailSheet(data: detail, isOwnEncounter: detail.isOwned)
        }
        .sheet(item: $appRouter.routedProfileId) { routed in
            NavigationStack {
                RemoteProfileContent(userID: routed.id, initialDisplayName: nil)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(CatchStrings.Common.done) {
                                appRouter.routedProfileId = nil
                            }
                            .foregroundStyle(CatchTheme.primary)
                        }
                    }
            }
        }
        .task {
            guard let userID = authService.authState.user?.id else { return }
            async let cats: Void = { try? await catDataService.loadCats() }()
            async let follows: Void = {
                try? await followService.refresh(for: userID)
            }()
            _ = await (cats, follows)
        }
    }
}
