import Foundation

@MainActor
public protocol FollowService: Observable, Sendable {
    var followers: [Follow] { get }
    var following: [Follow] { get }
    var outgoingPending: [Follow] { get }
    var pendingRequests: [Follow] { get }
    var isLoading: Bool { get }
    var hasMoreFollowers: Bool { get }
    var hasMoreFollowing: Bool { get }

    func follow(targetID: String, by userID: String, isTargetPrivate: Bool) async throws
    func unfollow(targetID: String, by userID: String) async throws
    func approveRequest(_ follow: Follow) async throws
    func declineRequest(_ follow: Follow) async throws
    func removeFollower(_ follow: Follow) async throws
    func refresh(for userID: String) async throws
    func loadMoreFollowers(for userID: String) async throws
    func loadMoreFollowing(for userID: String) async throws
    func fetchFollowCounts(for userID: String) async throws -> (followers: Int, following: Int)
    func fetchFollowers(for userID: String) async throws -> [Follow]
    func fetchFollowing(for userID: String) async throws -> [Follow]
    func isFollowing(_ targetID: String) -> Bool
    func pendingRequestTo(_ targetID: String) -> Follow?
    func startListening(for userID: String) async
    func stopListening() async
}
