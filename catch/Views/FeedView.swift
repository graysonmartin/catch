import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(CKSocialFeedService.self) private var socialFeedService: CKSocialFeedService?
    @Binding var scrollToTop: Bool
    @Binding var selectedTab: Int

    private var feedItems: [FeedItem] {
        (socialFeedService?.remoteEncounters ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if socialFeedService?.isLoading == true && (socialFeedService?.remoteEncounters.isEmpty ?? true) {
                    ProgressView()
                        .tint(CatchTheme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if socialFeedService?.remoteEncounters.isEmpty ?? true {
                    EmptyStateView(
                        icon: "person.2.circle",
                        title: CatchStrings.Feed.socialEmptyTitle,
                        subtitle: CatchStrings.Feed.socialEmptySubtitle
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: CatchSpacing.space16) {
                                ForEach(feedItems) { item in
                                    if case .remote(let encounter, let cat, let owner, let isFirstEncounter) = item {
                                        SocialFeedItemView(encounter: encounter, cat: cat, owner: owner, isFirstEncounter: isFirstEncounter)
                                    }
                                }
                            }
                            .padding()
                            .id("feedTop")
                        }
                        .onChange(of: scrollToTop) {
                            if scrollToTop {
                                withAnimation {
                                    proxy.scrollTo("feedTop", anchor: .top)
                                }
                                scrollToTop = false
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Tabs.feed)
            .navigationDestination(for: RemoteProfileRoute.self) { route in
                RemoteProfileContent(
                    userID: route.userID,
                    initialDisplayName: route.displayName
                )
            }
            .refreshable {
                await socialFeedService?.refresh()
            }
            .task(id: socialFeedService != nil) {
                await socialFeedService?.refresh()
                await loadInteractionData()
            }
        }
    }

    // MARK: - Data Loading

    private func loadInteractionData() async {
        guard let socialService else { return }
        let recordNames = socialFeedService?.remoteEncounters.compactMap(\.encounterRecordName) ?? []
        guard !recordNames.isEmpty else { return }
        try? await socialService.loadInteractionData(for: recordNames)
    }
}
