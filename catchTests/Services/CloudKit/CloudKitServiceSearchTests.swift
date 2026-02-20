import Testing

@MainActor
struct CloudKitServiceSearchTests {

    @Test func searchUsers_tracksQueryAndReturnsStub() async throws {
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

        #expect(results.count == 1)
        #expect(results[0].displayName == "Cat Lover")
        #expect(mock.searchUsersCalls == ["Cat"])
    }

    @Test func searchUsers_returnsEmptyByDefault() async throws {
        let mock = MockCloudKitService()

        let results = try await mock.searchUsers(query: "nobody")

        #expect(results.isEmpty)
        #expect(mock.searchUsersCalls == ["nobody"])
    }

    @Test func searchUsers_tracksMultipleCalls() async throws {
        let mock = MockCloudKitService()

        _ = try await mock.searchUsers(query: "first")
        _ = try await mock.searchUsers(query: "second")

        #expect(mock.searchUsersCalls.count == 2)
        #expect(mock.searchUsersCalls[0] == "first")
        #expect(mock.searchUsersCalls[1] == "second")
    }
}
