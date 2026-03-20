import SwiftUI
import CatchCore

struct FeedView: View {
    @Environment(FeedDataService.self) private var feedDataService
    @Environment(SupabaseSocialInteractionService.self) private var socialService: SupabaseSocialInteractionService?
    @Environment(DefaultSocialFeedService.self) private var socialFeedService: DefaultSocialFeedService?
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var scrollToTop: Bool
    @State private var isShowingFindPeople = false

    private var feedItems: [FeedItem] {
        let local = feedDataService.encounters.map { FeedItem.local($0) }
        let remote = socialFeedService?.remoteEncounters ?? []
        return (local + remote).sorted { $0.date > $1.date }
    }

    private var isEmpty: Bool {
        feedDataService.encounters.isEmpty && (socialFeedService?.remoteEncounters.isEmpty ?? true)
    }

    private var isInitialLoad: Bool {
        (socialFeedService?.isLoading == true || feedDataService.isLoading) && isEmpty
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingFindPeople = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(CatchTheme.primary)
                    }
                    .accessibilityLabel(CatchStrings.Accessibility.findPeople)
                }
            }
            .sheet(isPresented: $isShowingFindPeople) {
                FindPeopleView()
            }
            .navigationDestination(for: RemoteProfileRoute.self) { route in
                RemoteProfileContent(
                    userID: route.userID,
                    initialDisplayName: route.displayName
                )
            }
            .refreshable {
                async let local: Void = feedDataService.refresh()
                async let remote: Void = socialFeedService?.refresh() ?? ()
                _ = await (local, remote)
            }
            .task {
                let wasAlreadyLoaded = feedDataService.hasLoaded
                async let local: Void = feedDataService.loadIfNeeded()
                async let remote: Void = socialFeedService?.loadIfNeeded() ?? ()
                _ = await (local, remote)
                if !wasAlreadyLoaded {
                    await loadInteractionData()
                }
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
                    if reduceMotion {
                        proxy.scrollTo("feedTop", anchor: .top)
                    } else {
                        withAnimation {
                            proxy.scrollTo("feedTop", anchor: .top)
                        }
                    }
                    scrollToTop = false
                }
            }
        }
    }

    // MARK: - Load More

    @ViewBuilder
    private var loadMoreSection: some View {
        let hasLocalMore = feedDataService.hasMorePages
        let hasRemoteMore = socialFeedService?.hasMorePages == true
        let isLocalLoadingMore = feedDataService.isLoadingMore
        let isRemoteLoadingMore = socialFeedService?.isLoadingMore == true

        if hasLocalMore || hasRemoteMore {
            if isLocalLoadingMore || isRemoteLoadingMore {
                PawLoadingView(size: .inline)
                    .padding()
            } else {
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        Task {
                            async let localMore: Void = feedDataService.loadMore()
                            async let remoteMore: Void = {
                                if hasRemoteMore {
                                    await socialFeedService?.loadMore()
                                }
                            }()
                            _ = await (localMore, remoteMore)
                        }
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
        } catch where error.isCancellation {
        } catch {
            toastManager.showError(CatchStrings.Toast.feedLoadFailed)
        }
    }
}
