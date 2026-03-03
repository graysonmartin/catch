import Foundation
import Observation

@Observable
@MainActor
final class MockSocialFeedService: SocialFeedService {
    var remoteEncounters: [FeedItem] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    var hasMorePages = false
    private(set) var refreshCalls = 0
    private(set) var loadMoreCalls = 0

    func refresh() async {
        refreshCalls += 1
    }

    func loadMore() async {
        loadMoreCalls += 1
    }

    func reset() {
        remoteEncounters = []
        isLoading = false
        isLoadingMore = false
        hasMorePages = false
        refreshCalls = 0
        loadMoreCalls = 0
    }
}
