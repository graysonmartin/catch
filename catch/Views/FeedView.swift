import SwiftUI
import SwiftData

enum FeedSortOption: String, CaseIterable, Identifiable {
    case newest = "newest first"
    case oldest = "oldest first"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newest: CatchStrings.Feed.newestFirst
        case .oldest: CatchStrings.Feed.oldestFirst
        }
    }
}

struct FeedView: View {
    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(CKSocialFeedService.self) private var socialFeedService: CKSocialFeedService?
    @Binding var scrollToTop: Bool
    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var sortOption: FeedSortOption = .newest

    private var feedItems: [FeedItem] {
        var items = socialFeedService?.remoteEncounters ?? []

        if !searchText.isEmpty {
            items = items.filter { item in
                guard case .remote(let encounter, let cat, let owner, _) = item else { return false }
                let matchesCatName = cat?.displayName.localizedCaseInsensitiveContains(searchText) ?? false
                let matchesNotes = encounter.notes.localizedCaseInsensitiveContains(searchText)
                let matchesLocation = encounter.locationName.localizedCaseInsensitiveContains(searchText)
                let matchesOwner = owner.displayName.localizedCaseInsensitiveContains(searchText)
                return matchesCatName || matchesNotes || matchesLocation || matchesOwner
            }
        }

        switch sortOption {
        case .newest: return items.sorted { $0.date > $1.date }
        case .oldest: return items.sorted { $0.date < $1.date }
        }
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
                } else if feedItems.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: CatchStrings.Feed.searchEmptyTitle,
                        subtitle: CatchStrings.Feed.searchEmptySubtitle(searchText)
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
            .searchable(text: $searchText, prompt: CatchStrings.Feed.searchPrompt)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(CatchStrings.Common.sortBy, selection: $sortOption) {
                            ForEach(FeedSortOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(CatchTheme.primary)
                    }
                }
            }
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
