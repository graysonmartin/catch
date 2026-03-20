import SwiftUI
import CatchCore

struct ContentView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @Environment(SupabaseFollowService.self) private var followService
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(CatDataService.self) private var catDataService
    @Environment(EncounterDataService.self) private var encounterDataService
    @State private var selectedTab = 0
    @State private var feedScrollToTop = false
    @State private var routedEncounterDetail: EncounterDetailData?

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
            Task { await handleRoute(route) }
        }
        .sheet(item: $routedEncounterDetail) { detail in
            EncounterDetailSheet(data: detail, isOwnEncounter: detail.isOwned)
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

    // MARK: - Routing

    private func handleRoute(_ route: AppRoute) async {
        switch route {
        case .encounter(let id):
            appRouter.clearPendingRoute()
            do {
                guard let encounter = try await encounterDataService.fetchEncounter(id: id) else { return }
                let cat = try? await catDataService.fetchCat(id: encounter.catID)
                routedEncounterDetail = EncounterDetailData(supabase: encounter, cat: cat)
            } catch {
                // Silently fail — encounter may have been deleted
            }
        }
    }
}
