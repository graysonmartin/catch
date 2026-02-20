import XCTest

@MainActor
final class FriendshipTests: XCTestCase {

    private let now = Date()

    // MARK: - friendID(for:)

    func test_friendID_returnsOtherUser() {
        let friendship = Friendship(id: "f1", userA: "alice", userB: "bob", createdAt: now)
        XCTAssertEqual(friendship.friendID(for: "alice"), "bob")
        XCTAssertEqual(friendship.friendID(for: "bob"), "alice")
    }

    // MARK: - Deterministic Record Name

    func test_recordName_isDeterministic() {
        let name1 = Friendship.recordName(userID1: "alice", userID2: "bob")
        let name2 = Friendship.recordName(userID1: "bob", userID2: "alice")
        XCTAssertEqual(name1, name2)
    }

    func test_recordName_format() {
        let name = Friendship.recordName(userID1: "zz-user", userID2: "aa-user")
        XCTAssertEqual(name, "aa-user_zz-user")
    }

    func test_recordName_sameOrder() {
        let name = Friendship.recordName(userID1: "aaa", userID2: "bbb")
        XCTAssertEqual(name, "aaa_bbb")
    }

    // MARK: - Identifiable

    func test_identifiable() {
        let friendship = Friendship(id: "f1", userA: "a", userB: "b", createdAt: now)
        XCTAssertEqual(friendship.id, "f1")
    }

    // MARK: - Equatable

    func test_equatable() {
        let a = Friendship(id: "f1", userA: "alice", userB: "bob", createdAt: now)
        let b = Friendship(id: "f1", userA: "alice", userB: "bob", createdAt: now)
        XCTAssertEqual(a, b)

        let c = Friendship(id: "f2", userA: "alice", userB: "bob", createdAt: now)
        XCTAssertNotEqual(a, c)
    }
}
