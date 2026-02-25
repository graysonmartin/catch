import Foundation
import XCTest

@MainActor
final class MockFollowServiceTests: XCTestCase {

    func test_follow_tracksCallAndSucceeds() async throws {
        let mock = MockFollowService()
        try await mock.follow(targetID: "target", by: "user", isTargetPrivate: false)

        XCTAssertEqual(mock.followCalls.count, 1)
        XCTAssertEqual(mock.followCalls[0].targetID, "target")
        XCTAssertEqual(mock.followCalls[0].userID, "user")
        XCTAssertEqual(mock.followCalls[0].isTargetPrivate, false)
    }

    func test_follow_throwsWhenErrorSet() async {
        let mock = MockFollowService()
        mock.followError = .cannotFollowSelf

        do {
            try await mock.follow(targetID: "t", by: "u", isTargetPrivate: false)
            XCTFail("Expected error")
        } catch let error as FollowServiceError {
            XCTAssertEqual(error, .cannotFollowSelf)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_unfollow_tracksCall() async throws {
        let mock = MockFollowService()
        try await mock.unfollow(targetID: "target", by: "user")

        XCTAssertEqual(mock.unfollowCalls.count, 1)
        XCTAssertEqual(mock.unfollowCalls[0].targetID, "target")
    }

    func test_approveRequest_tracksCall() async throws {
        let mock = MockFollowService()
        let follow = Follow(id: "1", followerID: "a", followeeID: "b", status: .pending, createdAt: Date())
        try await mock.approveRequest(follow)

        XCTAssertEqual(mock.approveRequestCalls.count, 1)
        XCTAssertEqual(mock.approveRequestCalls[0].id, "1")
    }

    func test_declineRequest_tracksCall() async throws {
        let mock = MockFollowService()
        let follow = Follow(id: "2", followerID: "a", followeeID: "b", status: .pending, createdAt: Date())
        try await mock.declineRequest(follow)

        XCTAssertEqual(mock.declineRequestCalls.count, 1)
        XCTAssertEqual(mock.declineRequestCalls[0].id, "2")
    }

    func test_removeFollower_tracksCall() async throws {
        let mock = MockFollowService()
        let follow = Follow(id: "3", followerID: "a", followeeID: "b", status: .active, createdAt: Date())
        try await mock.removeFollower(follow)

        XCTAssertEqual(mock.removeFollowerCalls.count, 1)
    }

    func test_refresh_tracksUserID() async throws {
        let mock = MockFollowService()
        try await mock.refresh(for: "user-123")

        XCTAssertEqual(mock.refreshCalls, ["user-123"])
    }

    func test_isFollowing_checksFollowingArray() {
        let mock = MockFollowService()
        mock.simulateFollowing(followeeID: "target-1")

        XCTAssertTrue(mock.isFollowing("target-1"))
        XCTAssertFalse(mock.isFollowing("target-2"))
    }

    func test_pendingRequestTo_checksOutgoingPending() {
        let mock = MockFollowService()
        mock.outgoingPending = [
            Follow(id: "p1", followerID: "me", followeeID: "target-1", status: .pending, createdAt: Date())
        ]

        XCTAssertNotNil(mock.pendingRequestTo("target-1"))
        XCTAssertNil(mock.pendingRequestTo("target-2"))
    }

    func test_simulateHelpers_populateArrays() {
        let mock = MockFollowService()
        mock.simulateFollower(followerID: "f1")
        mock.simulateFollowing(followeeID: "f2")
        mock.simulatePendingRequest(followerID: "f3")

        XCTAssertEqual(mock.followers.count, 1)
        XCTAssertEqual(mock.following.count, 1)
        XCTAssertEqual(mock.pendingRequests.count, 1)
    }

    func test_reset_clearsEverything() async throws {
        let mock = MockFollowService()
        mock.simulateFollower(followerID: "f1")
        mock.followError = .notSignedIn
        try await mock.refresh(for: "user")

        mock.reset()

        XCTAssertTrue(mock.followers.isEmpty)
        XCTAssertTrue(mock.refreshCalls.isEmpty)
        XCTAssertNil(mock.followError)
    }
}
