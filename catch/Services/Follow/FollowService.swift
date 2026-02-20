import Foundation

@MainActor
protocol FollowService: Observable, Sendable {
    var followers: [Follow] { get }
    var following: [Follow] { get }
    var outgoingPending: [Follow] { get }
    var pendingRequests: [Follow] { get }
    var isLoading: Bool { get }

    func follow(targetID: String, by userID: String, isTargetPrivate: Bool) async throws
    func unfollow(targetID: String, by userID: String) async throws
    func approveRequest(_ follow: Follow) async throws
    func declineRequest(_ follow: Follow) async throws
    func removeFollower(_ follow: Follow) async throws
    func refresh(for userID: String) async throws
    func isFollowing(_ targetID: String) -> Bool
    func pendingRequestTo(_ targetID: String) -> Follow?
}
