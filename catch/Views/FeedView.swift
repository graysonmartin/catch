import SwiftUI
import SwiftData
import CatchCore

struct FeedView: View {
    @Query(sort: \Encounter.date, order: .reverse) private var localEncounters: [Encounter]
    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(CKSocialFeedService.self) private var socialFeedService: CKSocialFeedService?
    @Environment(ToastManager.self) private var toastManager
    @Binding var scrollToTop: Bool

    private var feedItems: [FeedItem] {
        let local = localEncounters.map { FeedItem.local($0) }

        // Remote feed now includes own CloudKit posts for cross-device visibility.
        // Deduplicate against local encounters to avoid showing the same post twice.
        let localRecordNames = Set(localEncounters.compactMap(\.cloudKitRecordName))
        let remote = (socialFeedService?.remoteEncounters ?? []).filter { item in
            guard let recordName = item.encounterRecordName else { return true }
            return !localRecordNames.contains(recordName)
        }

        return (local + remote).sorted { $0.date > $1.date }
    }

    private var isEmpty: Bool {
        localEncounters.isEmpty && (socialFeedService?.remoteEncounters.isEmpty ?? true)
    }

    private var isInitialLoad: Bool {
        socialFeedService?.isLoading == true && isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isInitialLoad {
                    PawLoadingView()
                } else if isEmpty {
                    EmptyStateView(
                        icon: "pawprint.circle",
                        title: CatchStrings.Feed.emptyTitle,
                        subtitle: CatchStrings.Feed.emptySubtitle
                    )
                } else {
                    feedList
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

    // MARK: - Subviews

    private var feedList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: CatchSpacing.space16) {
                    ForEach(feedItems) { item in
                        switch item {
                        case .local(let encounter):
                            FeedItemView(encounter: encounter)
                        case .remote(let encounter, let cat, let owner, let isFirstEncounter):
                            SocialFeedItemView(
                                encounter: encounter,
                                cat: cat,
                                owner: owner,
                                isFirstEncounter: isFirstEncounter,
                                catEncounters: allEncounters(forCatRecord: encounter.catRecordName)
                            )
                        }
                    }

                    loadMoreSection
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

    // MARK: - Load More

    @ViewBuilder
    private var loadMoreSection: some View {
        if socialFeedService?.hasMorePages == true {
            if socialFeedService?.isLoadingMore == true {
                PawLoadingView(size: .inline)
                    .padding()
            } else {
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        Task { await socialFeedService?.loadMore() }
                    }
            }
        }
    }

    // MARK: - Helpers

    private func allEncounters(forCatRecord recordName: String) -> [CloudEncounter] {
        feedItems.compactMap { item in
            guard case .remote(let encounter, _, _, _) = item,
                  encounter.catRecordName == recordName else { return nil }
            return encounter
        }
    }

    // MARK: - Data Loading

    private func loadInteractionData() async {
        guard let socialService else { return }
        let recordNames = feedItems.compactMap(\.encounterRecordName)
        guard !recordNames.isEmpty else { return }
        do {
            try await socialService.loadInteractionData(for: recordNames)
        } catch {
            toastManager.showError(CatchStrings.Toast.feedLoadFailed)
        }
    }
}
