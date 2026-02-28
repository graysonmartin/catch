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

    // MARK: - fetchUserProfiles (batch)

    func test_fetchUserProfiles_returnsMatchingProfiles() async throws {
        let mock = MockCloudKitService()
        let profile1 = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "First",
            bio: "",
            isPrivate: false
        )
        let profile2 = CloudUserProfile(
            recordName: "rec-2",
            appleUserID: "user-2",
            displayName: "Second",
            bio: "",
            isPrivate: false
        )
        mock.fetchUserProfilesResult = [profile1, profile2]

        let results = try await mock.fetchUserProfiles(appleUserIDs: ["user-1", "user-2"])

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(mock.fetchUserProfilesCalls.count, 1)
        XCTAssertEqual(mock.fetchUserProfilesCalls.first, ["user-1", "user-2"])
    }

    func test_fetchUserProfiles_filtersToRequestedIDs() async throws {
        let mock = MockCloudKitService()
        let profile1 = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "First",
            bio: "",
            isPrivate: false
        )
        let profile2 = CloudUserProfile(
            recordName: "rec-2",
            appleUserID: "user-2",
            displayName: "Second",
            bio: "",
            isPrivate: false
        )
        mock.fetchUserProfilesResult = [profile1, profile2]

        let results = try await mock.fetchUserProfiles(appleUserIDs: ["user-1"])

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.displayName, "First")
    }

    func test_fetchUserProfiles_returnsEmptyForEmptyInput() async throws {
        let mock = MockCloudKitService()

        let results = try await mock.fetchUserProfiles(appleUserIDs: [])

        XCTAssertTrue(results.isEmpty)
    }
}
