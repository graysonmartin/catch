import Foundation
import Observation

@Observable
@MainActor
final class MockSocialFeedService: SocialFeedService {
    var remoteEncounters: [FeedItem] = []
    private(set) var isLoading = false
    private(set) var refreshCalls = 0

    func refresh() async {
        refreshCalls += 1
    }

    func reset() {
        remoteEncounters = []
        isLoading = false
        refreshCalls = 0
    }
}
