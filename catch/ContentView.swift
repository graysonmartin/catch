import SwiftUI
import CatchCore

struct ContentView: View {
    @Environment(CKFollowService.self) private var followService
    @Environment(AppleAuthService.self) private var authService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label(CatchStrings.Tabs.feed, systemImage: "pawprint.fill")
                }
                .tag(0)

            AddEncounterView()
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
            do {
                try await followService.refresh(for: userID)
            } catch {
                // Initial refresh failure is non-critical — user can pull to refresh
            }
        }
    }
}
