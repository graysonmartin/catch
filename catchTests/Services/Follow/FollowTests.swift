import Foundation
import XCTest

@MainActor
final class FollowTests: XCTestCase {

    private func makeFollow(
        id: String = "test-id",
        followerID: String = "user-a",
        followeeID: String = "user-b",
        status: FollowStatus = .active
    ) -> Follow {
        Follow(
            id: id,
            followerID: followerID,
            followeeID: followeeID,
            status: status,
            createdAt: Date()
        )
    }

    func test_isActive_trueForActiveStatus() {
        let follow = makeFollow(status: .active)
        XCTAssertTrue(follow.isActive)
        XCTAssertFalse(follow.isPending)
    }

    func test_isPending_trueForPendingStatus() {
        let follow = makeFollow(status: .pending)
        XCTAssertTrue(follow.isPending)
        XCTAssertFalse(follow.isActive)
    }

    func test_equatable_matchesOnAllFields() {
        let date = Date()
        let a = Follow(id: "1", followerID: "a", followeeID: "b", status: .active, createdAt: date)
        let b = Follow(id: "1", followerID: "a", followeeID: "b", status: .active, createdAt: date)
        XCTAssertEqual(a, b)
    }

    func test_equatable_differsByStatus() {
        let date = Date()
        let a = Follow(id: "1", followerID: "a", followeeID: "b", status: .active, createdAt: date)
        let b = Follow(id: "1", followerID: "a", followeeID: "b", status: .pending, createdAt: date)
        XCTAssertNotEqual(a, b)
    }

    func test_id_matchesProvidedValue() {
        let follow = makeFollow(id: "custom-id")
        XCTAssertEqual(follow.id, "custom-id")
    }
}
