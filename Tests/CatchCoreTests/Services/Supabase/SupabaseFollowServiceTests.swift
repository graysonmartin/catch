import XCTest
@testable import CatchCore

@MainActor
final class SupabaseFollowServiceTests: XCTestCase {

    private var sut: SupabaseFollowService!
    private var mockRepo: MockSupabaseFollowRepository!
    private let currentUserID = "current-user"

    override func setUp() {
        super.setUp()
        mockRepo = MockSupabaseFollowRepository()
        sut = SupabaseFollowService(repository: mockRepo, pageSize: 3)
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        super.tearDown()
    }

    // MARK: - Follow

    func testFollowPublicUserAddsToFollowing() async throws {
        let targetID = UUID()
        mockRepo.insertFollowResult = .fixture(
            followerID: UUID(uuidString: currentUserID) ?? UUID(),
            followeeID: targetID,
            status: "active"
        )

        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: false)

        XCTAssertEqual(sut.following.count, 1)
        XCTAssertEqual(sut.following.first?.followeeID, targetID.uuidString)
        XCTAssertTrue(sut.following.first?.isActive ?? false)
        XCTAssertTrue(sut.outgoingPending.isEmpty)
    }

    func testFollowPrivateUserAddsToPending() async throws {
        let targetID = UUID()
        mockRepo.insertFollowResult = .fixture(
            followerID: UUID(uuidString: currentUserID) ?? UUID(),
            followeeID: targetID,
            status: "pending"
        )

        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: true)

        XCTAssertTrue(sut.following.isEmpty)
        XCTAssertEqual(sut.outgoingPending.count, 1)
        XCTAssertTrue(sut.outgoingPending.first?.isPending ?? false)
    }

    func testFollowSelfThrows() async throws {
        do {
            try await sut.follow(targetID: currentUserID, by: currentUserID, isTargetPrivate: false)
            XCTFail("Expected cannotFollowSelf error")
        } catch let error as FollowServiceError {
            XCTAssertEqual(error, .cannotFollowSelf)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertTrue(mockRepo.insertFollowCalls.isEmpty)
    }

    func testFollowAlreadyFollowingThrows() async throws {
        let targetID = UUID()
        mockRepo.insertFollowResult = .fixture(followeeID: targetID, status: "active")
        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: false)

        do {
            try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: false)
            XCTFail("Expected alreadyFollowing error")
        } catch let error as FollowServiceError {
            XCTAssertEqual(error, .alreadyFollowing)
        }
    }

    func testFollowAlreadyPendingThrows() async throws {
        let targetID = UUID()
        mockRepo.insertFollowResult = .fixture(followeeID: targetID, status: "pending")
        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: true)

        do {
            try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: true)
            XCTFail("Expected requestAlreadyPending error")
        } catch let error as FollowServiceError {
            XCTAssertEqual(error, .requestAlreadyPending)
        }
    }

    func testFollowSendsCorrectPayload() async throws {
        let targetID = UUID()
        mockRepo.insertFollowResult = .fixture(status: "pending")

        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: true)

        XCTAssertEqual(mockRepo.insertFollowCalls.count, 1)
        let payload = mockRepo.insertFollowCalls.first!
        XCTAssertEqual(payload.followerID, currentUserID)
        XCTAssertEqual(payload.followeeID, targetID.uuidString)
        XCTAssertEqual(payload.status, "pending")
    }

    // MARK: - Unfollow

    func testUnfollowRemovesFromFollowing() async throws {
        let targetID = UUID()
        let followID = UUID()
        mockRepo.insertFollowResult = .fixture(id: followID, followeeID: targetID, status: "active")
        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: false)
        XCTAssertEqual(sut.following.count, 1)

        try await sut.unfollow(targetID: targetID.uuidString, by: currentUserID)

        XCTAssertTrue(sut.following.isEmpty)
        XCTAssertEqual(mockRepo.deleteFollowCalls.count, 1)
        XCTAssertEqual(mockRepo.deleteFollowCalls.first, followID.uuidString)
    }

    func testUnfollowCancelsPendingRequest() async throws {
        let targetID = UUID()
        let followID = UUID()
        mockRepo.insertFollowResult = .fixture(id: followID, followeeID: targetID, status: "pending")
        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: true)
        XCTAssertEqual(sut.outgoingPending.count, 1)

        try await sut.unfollow(targetID: targetID.uuidString, by: currentUserID)

        XCTAssertTrue(sut.outgoingPending.isEmpty)
        XCTAssertEqual(mockRepo.deleteFollowCalls.first, followID.uuidString)
    }

    func testUnfollowNotFoundThrows() async throws {
        do {
            try await sut.unfollow(targetID: "nonexistent", by: currentUserID)
            XCTFail("Expected followNotFound error")
        } catch let error as FollowServiceError {
            XCTAssertEqual(error, .followNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Approve / Decline / Remove

    func testApproveRequestMovesToFollowers() async throws {
        let followerID = UUID()
        let followID = UUID()
        let pendingFollow = Follow(
            id: followID.uuidString,
            followerID: followerID.uuidString,
            followeeID: currentUserID,
            status: .pending,
            createdAt: Date()
        )

        // Simulate pending request loaded via refresh
        mockRepo.fetchFollowersResult = []
        mockRepo.fetchFollowingResult = []
        mockRepo.fetchPendingIncomingResult = [
            .fixture(id: followID, followerID: followerID, followeeID: UUID(uuidString: currentUserID) ?? UUID(), status: "pending")
        ]
        mockRepo.fetchPendingOutgoingResult = []
        try await sut.refresh(for: currentUserID)
        XCTAssertEqual(sut.pendingRequests.count, 1)

        mockRepo.updateFollowStatusResult = .fixture(
            id: followID, followerID: followerID,
            followeeID: UUID(uuidString: currentUserID) ?? UUID(),
            status: "active"
        )

        try await sut.approveRequest(sut.pendingRequests.first!)

        XCTAssertTrue(sut.pendingRequests.isEmpty)
        XCTAssertEqual(sut.followers.count, 1)
        XCTAssertTrue(sut.followers.first?.isActive ?? false)
        XCTAssertEqual(mockRepo.updateFollowStatusCalls.first?.status, "active")
    }

    func testDeclineRequestRemovesFromPending() async throws {
        let followID = UUID()
        let pendingFollow = Follow(
            id: followID.uuidString,
            followerID: "someone",
            followeeID: currentUserID,
            status: .pending,
            createdAt: Date()
        )

        mockRepo.fetchFollowersResult = []
        mockRepo.fetchFollowingResult = []
        mockRepo.fetchPendingIncomingResult = [
            .fixture(id: followID, followerID: UUID(), followeeID: UUID(uuidString: currentUserID) ?? UUID(), status: "pending")
        ]
        mockRepo.fetchPendingOutgoingResult = []
        try await sut.refresh(for: currentUserID)

        try await sut.declineRequest(sut.pendingRequests.first!)

        XCTAssertTrue(sut.pendingRequests.isEmpty)
        XCTAssertEqual(mockRepo.deleteFollowCalls.count, 1)
    }

    func testRemoveFollowerDeletesAndRemoves() async throws {
        let followerID = UUID()
        let followID = UUID()

        mockRepo.fetchFollowersResult = [
            .fixture(id: followID, followerID: followerID, followeeID: UUID(uuidString: currentUserID) ?? UUID(), status: "active")
        ]
        mockRepo.fetchFollowingResult = []
        mockRepo.fetchPendingIncomingResult = []
        mockRepo.fetchPendingOutgoingResult = []
        try await sut.refresh(for: currentUserID)
        XCTAssertEqual(sut.followers.count, 1)

        try await sut.removeFollower(sut.followers.first!)

        XCTAssertTrue(sut.followers.isEmpty)
        XCTAssertEqual(mockRepo.deleteFollowCalls.first, followID.uuidString)
    }

    // MARK: - Refresh

    func testRefreshPopulatesAllLists() async throws {
        let followerID = UUID()
        let followingID = UUID()
        let pendingInID = UUID()
        let pendingOutID = UUID()
        let myID = UUID(uuidString: currentUserID) ?? UUID()

        mockRepo.fetchFollowersResult = [
            .fixture(followerID: followerID, followeeID: myID, status: "active")
        ]
        mockRepo.fetchFollowingResult = [
            .fixture(followerID: myID, followeeID: followingID, status: "active")
        ]
        mockRepo.fetchPendingIncomingResult = [
            .fixture(followerID: pendingInID, followeeID: myID, status: "pending")
        ]
        mockRepo.fetchPendingOutgoingResult = [
            .fixture(followerID: myID, followeeID: pendingOutID, status: "pending")
        ]

        try await sut.refresh(for: currentUserID)

        XCTAssertEqual(sut.followers.count, 1)
        XCTAssertEqual(sut.following.count, 1)
        XCTAssertEqual(sut.pendingRequests.count, 1)
        XCTAssertEqual(sut.outgoingPending.count, 1)
        XCTAssertFalse(sut.isLoading)
    }

    func testRefreshSetsHasMoreWhenPageFull() async throws {
        // pageSize is 3 in setUp
        mockRepo.fetchFollowersResult = (0..<3).map { _ in SupabaseFollow.fixture() }
        mockRepo.fetchFollowingResult = [.fixture()]
        mockRepo.fetchPendingIncomingResult = []
        mockRepo.fetchPendingOutgoingResult = []

        try await sut.refresh(for: currentUserID)

        XCTAssertTrue(sut.hasMoreFollowers)
        XCTAssertFalse(sut.hasMoreFollowing)
    }

    func testRefreshRunsConcurrently() async throws {
        mockRepo.fetchFollowersResult = []
        mockRepo.fetchFollowingResult = []
        mockRepo.fetchPendingIncomingResult = []
        mockRepo.fetchPendingOutgoingResult = []

        try await sut.refresh(for: currentUserID)

        XCTAssertEqual(mockRepo.fetchFollowersCalls.count, 1)
        XCTAssertEqual(mockRepo.fetchFollowingCalls.count, 1)
        XCTAssertEqual(mockRepo.fetchPendingIncomingCalls.count, 1)
        XCTAssertEqual(mockRepo.fetchPendingOutgoingCalls.count, 1)
    }

    // MARK: - Pagination

    func testLoadMoreFollowersAppendsAndUpdatesHasMore() async throws {
        // Initial refresh with full page
        mockRepo.fetchFollowersResult = (0..<3).map { _ in SupabaseFollow.fixture() }
        mockRepo.fetchFollowingResult = []
        mockRepo.fetchPendingIncomingResult = []
        mockRepo.fetchPendingOutgoingResult = []
        try await sut.refresh(for: currentUserID)
        XCTAssertTrue(sut.hasMoreFollowers)
        XCTAssertEqual(sut.followers.count, 3)

        // Load more with partial page
        mockRepo.fetchFollowersResult = [.fixture()]
        try await sut.loadMoreFollowers(for: currentUserID)

        XCTAssertEqual(sut.followers.count, 4)
        XCTAssertFalse(sut.hasMoreFollowers)
        // Verify offset was 3
        let lastCall = mockRepo.fetchFollowersCalls.last!
        XCTAssertEqual(lastCall.offset, 3)
    }

    func testLoadMoreFollowingAppendsAndUpdatesHasMore() async throws {
        mockRepo.fetchFollowersResult = []
        mockRepo.fetchFollowingResult = (0..<3).map { _ in SupabaseFollow.fixture() }
        mockRepo.fetchPendingIncomingResult = []
        mockRepo.fetchPendingOutgoingResult = []
        try await sut.refresh(for: currentUserID)
        XCTAssertTrue(sut.hasMoreFollowing)

        mockRepo.fetchFollowingResult = [.fixture(), .fixture()]
        try await sut.loadMoreFollowing(for: currentUserID)

        XCTAssertEqual(sut.following.count, 5)
        XCTAssertFalse(sut.hasMoreFollowing)
        XCTAssertEqual(mockRepo.fetchFollowingCalls.last?.offset, 3)
    }

    func testLoadMoreFollowersNoOpWhenNoMore() async throws {
        // hasMoreFollowers defaults to false
        try await sut.loadMoreFollowers(for: currentUserID)

        XCTAssertTrue(mockRepo.fetchFollowersCalls.isEmpty)
    }

    func testLoadMoreFollowingNoOpWhenNoMore() async throws {
        try await sut.loadMoreFollowing(for: currentUserID)

        XCTAssertTrue(mockRepo.fetchFollowingCalls.isEmpty)
    }

    // MARK: - Counts

    func testFetchFollowCountsReturnsBothCounts() async throws {
        mockRepo.countFollowersResult = 42
        mockRepo.countFollowingResult = 7

        let counts = try await sut.fetchFollowCounts(for: "some-user")

        XCTAssertEqual(counts.followers, 42)
        XCTAssertEqual(counts.following, 7)
    }

    // MARK: - Fetch Lists

    func testFetchFollowersReturnsMappedDomainObjects() async throws {
        let id = UUID()
        mockRepo.fetchFollowersResult = [.fixture(id: id, status: "active")]

        let result = try await sut.fetchFollowers(for: "some-user")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, id.uuidString)
        XCTAssertTrue(result.first?.isActive ?? false)
    }

    func testFetchFollowingReturnsMappedDomainObjects() async throws {
        let id = UUID()
        mockRepo.fetchFollowingResult = [.fixture(id: id, status: "active")]

        let result = try await sut.fetchFollowing(for: "some-user")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, id.uuidString)
    }

    // MARK: - Cache Lookups

    func testIsFollowingReturnsTrueForFollowedUser() async throws {
        let targetID = UUID()
        mockRepo.insertFollowResult = .fixture(followeeID: targetID, status: "active")
        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: false)

        XCTAssertTrue(sut.isFollowing(targetID.uuidString))
        XCTAssertFalse(sut.isFollowing("unknown"))
    }

    func testPendingRequestToReturnsMatchingPending() async throws {
        let targetID = UUID()
        mockRepo.insertFollowResult = .fixture(followeeID: targetID, status: "pending")
        try await sut.follow(targetID: targetID.uuidString, by: currentUserID, isTargetPrivate: true)

        XCTAssertNotNil(sut.pendingRequestTo(targetID.uuidString))
        XCTAssertNil(sut.pendingRequestTo("unknown"))
    }
}
