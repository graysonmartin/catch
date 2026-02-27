import XCTest
@testable import CatchCore

@MainActor
final class CloudKitServiceSearchTests: XCTestCase {

    func test_searchUsers_tracksQueryAndReturnsStub() async throws {
        let mock = MockCloudKitService()
        let profile = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "Cat Lover",
            bio: "meow",
            isPrivate: false
        )
        mock.searchUsersResult = [profile]

        let results = try await mock.searchUsers(query: "Cat")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].displayName, "Cat Lover")
        XCTAssertEqual(mock.searchUsersCalls, ["Cat"])
    }

    func test_searchUsers_returnsEmptyByDefault() async throws {
        let mock = MockCloudKitService()

        let results = try await mock.searchUsers(query: "nobody")

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(mock.searchUsersCalls, ["nobody"])
    }

    func test_searchUsers_tracksMultipleCalls() async throws {
        let mock = MockCloudKitService()

        _ = try await mock.searchUsers(query: "first")
        _ = try await mock.searchUsers(query: "second")

        XCTAssertEqual(mock.searchUsersCalls.count, 2)
        XCTAssertEqual(mock.searchUsersCalls[0], "first")
        XCTAssertEqual(mock.searchUsersCalls[1], "second")
    }
}
