import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockFollowService: FollowService {
    var followers: [Follow] = []
    var following: [Follow] = []
    var outgoingPending: [Follow] = []
    var pendingRequests: [Follow] = []
    var isLoading = false

    private(set) var followCalls: [(targetID: String, userID: String, isTargetPrivate: Bool)] = []
    private(set) var unfollowCalls: [(targetID: String, userID: String)] = []
    private(set) var approveRequestCalls: [Follow] = []
    private(set) var declineRequestCalls: [Follow] = []
    private(set) var removeFollowerCalls: [Follow] = []
    private(set) var refreshCalls: [String] = []
    private(set) var fetchFollowCountsCalls: [String] = []

    var stubbedFollowCounts: (followers: Int, following: Int) = (0, 0)
    var followError: FollowServiceError?
    var unfollowError: FollowServiceError?
    var approveError: FollowServiceError?
    var declineError: FollowServiceError?
    var removeError: FollowServiceError?

    func follow(targetID: String, by userID: String, isTargetPrivate: Bool) async throws {
        followCalls.append((targetID, userID, isTargetPrivate))
        if let error = followError { throw error }
    }

    func unfollow(targetID: String, by userID: String) async throws {
        unfollowCalls.append((targetID, userID))
        if let error = unfollowError { throw error }
    }

    func approveRequest(_ follow: Follow) async throws {
        approveRequestCalls.append(follow)
        if let error = approveError { throw error }
    }

    func declineRequest(_ follow: Follow) async throws {
        declineRequestCalls.append(follow)
        if let error = declineError { throw error }
    }

    func removeFollower(_ follow: Follow) async throws {
        removeFollowerCalls.append(follow)
        if let error = removeError { throw error }
    }

    func refresh(for userID: String) async throws {
        refreshCalls.append(userID)
    }

    func fetchFollowCounts(for userID: String) async throws -> (followers: Int, following: Int) {
        fetchFollowCountsCalls.append(userID)
        return stubbedFollowCounts
    }

    func isFollowing(_ targetID: String) -> Bool {
        following.contains { $0.followeeID == targetID }
    }

    func pendingRequestTo(_ targetID: String) -> Follow? {
        outgoingPending.first { $0.followeeID == targetID }
    }

    // MARK: - Test Helpers

    func simulateFollower(id: String = UUID().uuidString, followerID: String) {
        followers.append(Follow(
            id: id,
            followerID: followerID,
            followeeID: "current-user",
            status: .active,
            createdAt: Date()
        ))
    }

    func simulateFollowing(id: String = UUID().uuidString, followeeID: String) {
        following.append(Follow(
            id: id,
            followerID: "current-user",
            followeeID: followeeID,
            status: .active,
            createdAt: Date()
        ))
    }

    func simulatePendingRequest(id: String = UUID().uuidString, followerID: String) {
        pendingRequests.append(Follow(
            id: id,
            followerID: followerID,
            followeeID: "current-user",
            status: .pending,
            createdAt: Date()
        ))
    }

    func reset() {
        followers = []
        following = []
        outgoingPending = []
        pendingRequests = []
        followCalls = []
        unfollowCalls = []
        approveRequestCalls = []
        declineRequestCalls = []
        removeFollowerCalls = []
        refreshCalls = []
        fetchFollowCountsCalls = []
        stubbedFollowCounts = (0, 0)
        followError = nil
        unfollowError = nil
        approveError = nil
        declineError = nil
        removeError = nil
    }
}
