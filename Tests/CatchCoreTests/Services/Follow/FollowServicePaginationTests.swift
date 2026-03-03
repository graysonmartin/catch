import XCTest
@testable import CatchCore

@MainActor
final class FollowServicePaginationTests: XCTestCase {

    private var mockService: MockFollowService!

    override func setUp() {
        super.setUp()
        mockService = MockFollowService()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    // MARK: - hasMoreFollowers / hasMoreFollowing

    func testHasMoreFollowersDefaultsToFalse() {
        XCTAssertFalse(mockService.hasMoreFollowers)
    }

    func testHasMoreFollowingDefaultsToFalse() {
        XCTAssertFalse(mockService.hasMoreFollowing)
    }

    func testHasMoreFollowersCanBeSet() {
        mockService.hasMoreFollowers = true
        XCTAssertTrue(mockService.hasMoreFollowers)
    }

    func testHasMoreFollowingCanBeSet() {
        mockService.hasMoreFollowing = true
        XCTAssertTrue(mockService.hasMoreFollowing)
    }

    // MARK: - loadMore calls

    func testLoadMoreFollowersRecordsCalls() async throws {
        try await mockService.loadMoreFollowers(for: "user-1")
        try await mockService.loadMoreFollowers(for: "user-2")

        XCTAssertEqual(mockService.loadMoreFollowersCalls, ["user-1", "user-2"])
    }

    func testLoadMoreFollowingRecordsCalls() async throws {
        try await mockService.loadMoreFollowing(for: "user-1")

        XCTAssertEqual(mockService.loadMoreFollowingCalls, ["user-1"])
    }

    // MARK: - Reset

    func testResetClearsPaginationState() {
        mockService.hasMoreFollowers = true
        mockService.hasMoreFollowing = true

        mockService.reset()

        XCTAssertFalse(mockService.hasMoreFollowers)
        XCTAssertFalse(mockService.hasMoreFollowing)
        XCTAssertTrue(mockService.loadMoreFollowersCalls.isEmpty)
        XCTAssertTrue(mockService.loadMoreFollowingCalls.isEmpty)
    }
}
