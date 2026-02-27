import Foundation

@MainActor
protocol SocialFeedService: Observable, Sendable {
    var remoteEncounters: [FeedItem] { get }
    var isLoading: Bool { get }

    func refresh() async
}
