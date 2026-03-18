import Foundation
import Observation

@Observable
@MainActor
final class MockSocialFeedService: SocialFeedService {
    var remoteEncounters: [FeedItem] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    var hasMorePages = false
    private(set) var hasLoaded = false
    private(set) var refreshCalls = 0
    private(set) var loadMoreCalls = 0
    private(set) var loadIfNeededCalls = 0

    func loadIfNeeded() async {
        loadIfNeededCalls += 1
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        refreshCalls += 1
        hasLoaded = true
    }

    func loadMore() async {
        loadMoreCalls += 1
    }

    func reset() {
        remoteEncounters = []
        isLoading = false
        isLoadingMore = false
        hasMorePages = false
        hasLoaded = false
        refreshCalls = 0
        loadMoreCalls = 0
        loadIfNeededCalls = 0
    }
}
