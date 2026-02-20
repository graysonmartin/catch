import Foundation
import Testing

@MainActor
struct FollowTests {

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

    @Test func isActive_trueForActiveStatus() {
        let follow = makeFollow(status: .active)
        #expect(follow.isActive)
        #expect(!follow.isPending)
    }

    @Test func isPending_trueForPendingStatus() {
        let follow = makeFollow(status: .pending)
        #expect(follow.isPending)
        #expect(!follow.isActive)
    }

    @Test func equatable_matchesOnAllFields() {
        let date = Date()
        let a = Follow(id: "1", followerID: "a", followeeID: "b", status: .active, createdAt: date)
        let b = Follow(id: "1", followerID: "a", followeeID: "b", status: .active, createdAt: date)
        #expect(a == b)
    }

    @Test func equatable_differsByStatus() {
        let date = Date()
        let a = Follow(id: "1", followerID: "a", followeeID: "b", status: .active, createdAt: date)
        let b = Follow(id: "1", followerID: "a", followeeID: "b", status: .pending, createdAt: date)
        #expect(a != b)
    }

    @Test func id_matchesProvidedValue() {
        let follow = makeFollow(id: "custom-id")
        #expect(follow.id == "custom-id")
    }
}
