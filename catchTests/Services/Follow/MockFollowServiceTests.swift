import Foundation
import Testing

@MainActor
struct MockFollowServiceTests {

    @Test func follow_tracksCallAndSucceeds() async throws {
        let mock = MockFollowService()
        try await mock.follow(targetID: "target", by: "user", isTargetPrivate: false)

        #expect(mock.followCalls.count == 1)
        #expect(mock.followCalls[0].targetID == "target")
        #expect(mock.followCalls[0].userID == "user")
        #expect(mock.followCalls[0].isTargetPrivate == false)
    }

    @Test func follow_throwsWhenErrorSet() async {
        let mock = MockFollowService()
        mock.followError = .cannotFollowSelf

        do {
            try await mock.follow(targetID: "t", by: "u", isTargetPrivate: false)
            Issue.record("Expected error")
        } catch let error as FollowServiceError {
            #expect(error == .cannotFollowSelf)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test func unfollow_tracksCall() async throws {
        let mock = MockFollowService()
        try await mock.unfollow(targetID: "target", by: "user")

        #expect(mock.unfollowCalls.count == 1)
        #expect(mock.unfollowCalls[0].targetID == "target")
    }

    @Test func approveRequest_tracksCall() async throws {
        let mock = MockFollowService()
        let follow = Follow(id: "1", followerID: "a", followeeID: "b", status: .pending, createdAt: Date())
        try await mock.approveRequest(follow)

        #expect(mock.approveRequestCalls.count == 1)
        #expect(mock.approveRequestCalls[0].id == "1")
    }

    @Test func declineRequest_tracksCall() async throws {
        let mock = MockFollowService()
        let follow = Follow(id: "2", followerID: "a", followeeID: "b", status: .pending, createdAt: Date())
        try await mock.declineRequest(follow)

        #expect(mock.declineRequestCalls.count == 1)
        #expect(mock.declineRequestCalls[0].id == "2")
    }

    @Test func removeFollower_tracksCall() async throws {
        let mock = MockFollowService()
        let follow = Follow(id: "3", followerID: "a", followeeID: "b", status: .active, createdAt: Date())
        try await mock.removeFollower(follow)

        #expect(mock.removeFollowerCalls.count == 1)
    }

    @Test func refresh_tracksUserID() async throws {
        let mock = MockFollowService()
        try await mock.refresh(for: "user-123")

        #expect(mock.refreshCalls == ["user-123"])
    }

    @Test func isFollowing_checksFollowingArray() {
        let mock = MockFollowService()
        mock.simulateFollowing(followeeID: "target-1")

        #expect(mock.isFollowing("target-1"))
        #expect(!mock.isFollowing("target-2"))
    }

    @Test func pendingRequestTo_checksOutgoingPending() {
        let mock = MockFollowService()
        mock.outgoingPending = [
            Follow(id: "p1", followerID: "me", followeeID: "target-1", status: .pending, createdAt: Date())
        ]

        #expect(mock.pendingRequestTo("target-1") != nil)
        #expect(mock.pendingRequestTo("target-2") == nil)
    }

    @Test func simulateHelpers_populateArrays() {
        let mock = MockFollowService()
        mock.simulateFollower(followerID: "f1")
        mock.simulateFollowing(followeeID: "f2")
        mock.simulatePendingRequest(followerID: "f3")

        #expect(mock.followers.count == 1)
        #expect(mock.following.count == 1)
        #expect(mock.pendingRequests.count == 1)
    }

    @Test func reset_clearsEverything() async throws {
        let mock = MockFollowService()
        mock.simulateFollower(followerID: "f1")
        mock.followError = .notSignedIn
        try await mock.refresh(for: "user")

        mock.reset()

        #expect(mock.followers.isEmpty)
        #expect(mock.refreshCalls.isEmpty)
        #expect(mock.followError == nil)
    }
}
