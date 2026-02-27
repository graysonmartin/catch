import XCTest

@MainActor
final class FetchFollowCountsTests: XCTestCase {

    func testFetchFollowCountsReturnsStubbedValues() async throws {
        let mock = MockFollowService()
        mock.stubbedFollowCounts = (followers: 12, following: 5)

        let counts = try await mock.fetchFollowCounts(for: "user-123")

        XCTAssertEqual(counts.followers, 12)
        XCTAssertEqual(counts.following, 5)
        XCTAssertEqual(mock.fetchFollowCountsCalls, ["user-123"])
    }

    func testFetchFollowCountsDefaultsToZero() async throws {
        let mock = MockFollowService()

        let counts = try await mock.fetchFollowCounts(for: "user-abc")

        XCTAssertEqual(counts.followers, 0)
        XCTAssertEqual(counts.following, 0)
    }

    func testFetchFollowCountsTracksMultipleCalls() async throws {
        let mock = MockFollowService()
        mock.stubbedFollowCounts = (followers: 3, following: 7)

        _ = try await mock.fetchFollowCounts(for: "user-a")
        _ = try await mock.fetchFollowCounts(for: "user-b")

        XCTAssertEqual(mock.fetchFollowCountsCalls, ["user-a", "user-b"])
    }

    func testResetClearsFetchFollowCountsState() async throws {
        let mock = MockFollowService()
        mock.stubbedFollowCounts = (followers: 10, following: 20)
        _ = try await mock.fetchFollowCounts(for: "user-x")

        mock.reset()

        XCTAssertEqual(mock.stubbedFollowCounts.followers, 0)
        XCTAssertEqual(mock.stubbedFollowCounts.following, 0)
        XCTAssertTrue(mock.fetchFollowCountsCalls.isEmpty)
    }
}
