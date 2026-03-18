import Foundation

@MainActor
protocol SocialFeedService: Observable, Sendable {
    var remoteEncounters: [FeedItem] { get }
    var isLoading: Bool { get }
    var isLoadingMore: Bool { get }
    var hasMorePages: Bool { get }
    var hasLoaded: Bool { get }

    func loadIfNeeded() async
    func refresh() async
    func loadMore() async
}
