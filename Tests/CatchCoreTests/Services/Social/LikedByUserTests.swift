import XCTest
@testable import CatchCore

@MainActor
final class LikedByUserTests: XCTestCase {

    // MARK: - Model Tests

    func test_likedByUser_identifiable() {
        let user = makeLikedByUser(id: "like-1")

        XCTAssertEqual(user.id, "like-1")
    }

    func test_likedByUser_equatable() {
        let date = Date()
        let a = LikedByUser(
            id: "like-1",
            userID: "user-1",
            displayName: "tuong",
            username: "tuong_cats",
            likedAt: date
        )
        let b = LikedByUser(
            id: "like-1",
            userID: "user-1",
            displayName: "tuong",
            username: "tuong_cats",
            likedAt: date
        )

        XCTAssertEqual(a, b)
    }

    func test_likedByUser_notEqual_differentID() {
        let date = Date()
        let a = LikedByUser(id: "like-1", userID: "user-1", displayName: "tuong", username: nil, likedAt: date)
        let b = LikedByUser(id: "like-2", userID: "user-1", displayName: "tuong", username: nil, likedAt: date)

        XCTAssertNotEqual(a, b)
    }

    func test_likedByUser_nilUsername() {
        let user = LikedByUser(
            id: "like-1",
            userID: "user-1",
            displayName: "tuong",
            username: nil,
            likedAt: Date()
        )

        XCTAssertNil(user.username)
    }

    // MARK: - Mock fetchLikes Tests

    func test_fetchLikes_returnsConfiguredResult() async throws {
        let mock = MockSocialInteractionService()
        let fakeUser = makeLikedByUser(id: "like-1")
        mock.fetchLikesResult = ([fakeUser], nil)

        let (users, cursor) = try await mock.fetchLikes(
            encounterRecordName: "enc1",
            cursor: nil
        )

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.displayName, "tuong")
        XCTAssertNil(cursor)
        XCTAssertEqual(mock.fetchLikesCalls.count, 1)
        XCTAssertEqual(mock.fetchLikesCalls.first?.encounterRecordName, "enc1")
    }

    func test_fetchLikes_returnsEmptyForNoLikes() async throws {
        let mock = MockSocialInteractionService()
        mock.fetchLikesResult = ([], nil)

        let (users, cursor) = try await mock.fetchLikes(
            encounterRecordName: "enc1",
            cursor: nil
        )

        XCTAssertTrue(users.isEmpty)
        XCTAssertNil(cursor)
    }

    func test_fetchLikes_passesCursorThrough() async throws {
        let mock = MockSocialInteractionService()
        let fakeUser = makeLikedByUser(id: "like-2")
        mock.fetchLikesResult = ([fakeUser], "has_more")

        let (users, cursor) = try await mock.fetchLikes(
            encounterRecordName: "enc1",
            cursor: "page2"
        )

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(cursor, "has_more")
        XCTAssertEqual(mock.fetchLikesCalls.first?.cursor, "page2")
    }

    func test_fetchLikes_multiplePages() async throws {
        let mock = MockSocialInteractionService()
        let user1 = makeLikedByUser(id: "like-1", displayName: "tuong")
        let user2 = makeLikedByUser(id: "like-2", displayName: "sophi")

        // First page
        mock.fetchLikesResult = ([user1], "has_more")
        let (firstPage, firstCursor) = try await mock.fetchLikes(
            encounterRecordName: "enc1",
            cursor: nil
        )
        XCTAssertEqual(firstPage.count, 1)
        XCTAssertEqual(firstCursor, "has_more")

        // Second page
        mock.fetchLikesResult = ([user2], nil)
        let (secondPage, secondCursor) = try await mock.fetchLikes(
            encounterRecordName: "enc1",
            cursor: "has_more"
        )
        XCTAssertEqual(secondPage.count, 1)
        XCTAssertNil(secondCursor)

        XCTAssertEqual(mock.fetchLikesCalls.count, 2)
    }

    func test_reset_clearsFetchLikesState() async throws {
        let mock = MockSocialInteractionService()
        let fakeUser = makeLikedByUser(id: "like-1")
        mock.fetchLikesResult = ([fakeUser], nil)
        _ = try await mock.fetchLikes(encounterRecordName: "enc1", cursor: nil)

        mock.reset()

        XCTAssertTrue(mock.fetchLikesCalls.isEmpty)
        let (users, _) = try await mock.fetchLikes(encounterRecordName: "enc1", cursor: nil)
        XCTAssertTrue(users.isEmpty)
    }

    // MARK: - Helpers

    private func makeLikedByUser(
        id: String = "like-1",
        userID: String = "user-1",
        displayName: String = "tuong",
        username: String? = "tuong_cats"
    ) -> LikedByUser {
        LikedByUser(
            id: id,
            userID: userID,
            displayName: displayName,
            username: username,
            likedAt: Date()
        )
    }
}
