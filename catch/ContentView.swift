import SwiftUI
import CatchCore

struct ContentView: View {
    @Environment(CKFollowService.self) private var followService
    @Environment(AppleAuthService.self) private var authService
    @State private var selectedTab = 0
    @State private var feedScrollToTop = false

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(scrollToTop: $feedScrollToTop, selectedTab: $selectedTab)
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
        .task {
            guard let userID = authService.authState.user?.userIdentifier else { return }
            try? await followService.refresh(for: userID)
        }
    }
}
