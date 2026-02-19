import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var feedScrollToTop = false

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(scrollToTop: $feedScrollToTop)
                .tabItem {
                    Label("Feed", systemImage: "pawprint.fill")
                }
                .tag(0)

            AddEncounterView(selectedTab: $selectedTab, feedScrollToTop: $feedScrollToTop)
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }
                .tag(1)

            CatMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(2)

            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2.fill")
                }
                .tag(3)
        }
        .tint(CatchTheme.primary)
    }
}
