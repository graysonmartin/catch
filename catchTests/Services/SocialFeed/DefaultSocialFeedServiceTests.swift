import XCTest
import CatchCore

@MainActor
final class DefaultSocialFeedServiceTests: XCTestCase {
    private var sut: DefaultSocialFeedService!
    private var mockRepo: MockSupabaseFeedRepository!
    private var mockFollowService: MockFollowService!

    override func setUp() {
        super.setUp()
        mockRepo = MockSupabaseFeedRepository()
        mockFollowService = MockFollowService()
        sut = DefaultSocialFeedService(
            repository: mockRepo,
            followService: mockFollowService,
            pageSize: 3
        )
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        mockFollowService = nil
        super.tearDown()
    }

    // MARK: - Empty State

    func testRefreshWithNoFollowsReturnsEmpty() async {
        await sut.refresh()

        XCTAssertTrue(sut.remoteEncounters.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.hasMorePages)
    }

    // MARK: - Basic Feed Loading

    func testRefreshFetchesFeedFromRepository() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")
        mockFollowService.simulateFollowing(followeeID: "user-b")

        let catID = UUID()
        let ownerID = UUID()
        mockRepo.fetchFeedResult = [
            .fixture(ownerID: ownerID, catID: catID)
        ]

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(mockRepo.fetchFeedCalls.count, 1)

        let call = mockRepo.fetchFeedCalls[0]
        XCTAssertTrue(call.followedUserIDs.contains("user-a"))
        XCTAssertTrue(call.followedUserIDs.contains("user-b"))
        XCTAssertNil(call.cursor)
    }

    func testRefreshPassesFollowedUserIDsToRepository() async {
        mockFollowService.simulateFollowing(followeeID: "user-x")

        mockRepo.fetchFeedResult = []
        await sut.refresh()

        XCTAssertEqual(mockRepo.fetchFeedCalls.count, 1)
        XCTAssertEqual(mockRepo.fetchFeedCalls[0].followedUserIDs, ["user-x"])
    }

    // MARK: - Feed Items Mapped Correctly

    func testFeedItemsHaveCorrectEncounterData() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        let encounterID = UUID()
        let catID = UUID()
        let ownerID = UUID()
        let date = Date()

        mockRepo.fetchFeedResult = [
            .fixture(
                id: encounterID,
                ownerID: ownerID,
                catID: catID,
                date: date,
                cat: .fixture(id: catID, name: "Whiskers"),
                owner: .fixture(id: ownerID, displayName: "alice")
            )
        ]

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 1)
        guard case .remote(let encounter, let cat, let owner, _) = sut.remoteEncounters.first else {
            XCTFail("Expected remote feed item")
            return
        }
        XCTAssertEqual(encounter.recordName, encounterID.uuidString)
        XCTAssertEqual(cat?.name, "Whiskers")
        XCTAssertEqual(owner.displayName, "alice")
    }

    // MARK: - Pagination

    func testRefreshSetsHasMorePagesWhenPageIsFull() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        // Page size is 3, return exactly 3 rows
        mockRepo.fetchFeedResult = (0..<3).map { _ in
            SupabaseFeedRow.fixture()
        }

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 3)
        XCTAssertTrue(sut.hasMorePages)
    }

    func testRefreshSetsNoMorePagesWhenPageIsPartial() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        // Page size is 3, return only 2 rows
        mockRepo.fetchFeedResult = (0..<2).map { _ in
            SupabaseFeedRow.fixture()
        }

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 2)
        XCTAssertFalse(sut.hasMorePages)
    }

    func testLoadMoreAppendsToExistingFeed() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        let firstPage = (0..<3).map { i in
            SupabaseFeedRow.fixture(
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            )
        }

        let secondPage = (3..<5).map { i in
            SupabaseFeedRow.fixture(
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            )
        }

        // First call (refresh) returns first page, second call (loadMore) returns second page
        let lastDate = firstPage.last.map { ISO8601DateFormatter().string(from: $0.date) }
        mockRepo.fetchFeedResultsByCursor = [
            nil: firstPage,
            lastDate: secondPage
        ]

        await sut.refresh()
        XCTAssertEqual(sut.remoteEncounters.count, 3)
        XCTAssertTrue(sut.hasMorePages)

        await sut.loadMore()
        XCTAssertEqual(sut.remoteEncounters.count, 5)
        XCTAssertFalse(sut.hasMorePages)
    }

    func testLoadMorePassesCursorToRepository() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        let date = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        mockRepo.fetchFeedResult = [
            .fixture(date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
            .fixture(date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()),
            .fixture(date: date)
        ]

        await sut.refresh()

        // loadMore should pass the date of the last item as cursor
        mockRepo.fetchFeedResult = []
        await sut.loadMore()

        XCTAssertEqual(mockRepo.fetchFeedCalls.count, 2)
        let cursor = mockRepo.fetchFeedCalls[1].cursor
        XCTAssertNotNil(cursor)
        XCTAssertEqual(cursor, ISO8601DateFormatter().string(from: date))
    }

    func testLoadMoreDoesNothingWhenNoMorePages() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        // Return fewer than pageSize (3), so no more pages
        mockRepo.fetchFeedResult = [.fixture()]

        await sut.refresh()
        XCTAssertFalse(sut.hasMorePages)

        await sut.loadMore()

        // Should only have called fetchFeed once (for refresh)
        XCTAssertEqual(mockRepo.fetchFeedCalls.count, 1)
    }

    // MARK: - Error Handling

    func testRefreshClearsEncountersOnError() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        mockRepo.errorToThrow = NSError(
            domain: "test",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "server error"]
        )

        await sut.refresh()

        XCTAssertTrue(sut.remoteEncounters.isEmpty)
        XCTAssertFalse(sut.hasMorePages)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadMoreStopsPaginationOnError() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        mockRepo.fetchFeedResult = (0..<3).map { _ in
            SupabaseFeedRow.fixture()
        }

        await sut.refresh()
        XCTAssertTrue(sut.hasMorePages)

        mockRepo.errorToThrow = NSError(
            domain: "test",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "server error"]
        )

        await sut.loadMore()

        // Original items preserved, but pagination stopped
        XCTAssertEqual(sut.remoteEncounters.count, 3)
        XCTAssertFalse(sut.hasMorePages)
    }

    // MARK: - Loading States

    func testIsLoadingFalseAfterRefresh() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")
        mockRepo.fetchFeedResult = []

        await sut.refresh()

        XCTAssertFalse(sut.isLoading)
    }

    func testIsLoadingMoreFalseAfterLoadMore() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")
        mockRepo.fetchFeedResult = (0..<3).map { _ in .fixture() }

        await sut.refresh()
        mockRepo.fetchFeedResult = []

        await sut.loadMore()

        XCTAssertFalse(sut.isLoadingMore)
    }

    // MARK: - Refresh Resets State

    func testRefreshResetsPreviousResults() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        mockRepo.fetchFeedResult = (0..<3).map { _ in .fixture() }
        await sut.refresh()
        XCTAssertEqual(sut.remoteEncounters.count, 3)

        // Refresh with new data
        mockRepo.fetchFeedResult = [.fixture()]
        await sut.refresh()
        XCTAssertEqual(sut.remoteEncounters.count, 1)
    }
}

// MARK: - Fixtures

extension SupabaseFeedRow {
    static func fixture(
        id: UUID = UUID(),
        ownerID: UUID = UUID(),
        catID: UUID = UUID(),
        date: Date = Date(),
        locationName: String? = "park",
        locationLat: Double? = 37.7749,
        locationLng: Double? = -122.4194,
        notes: String? = nil,
        photoUrls: [String] = [],
        likeCount: Int = 0,
        commentCount: Int = 0,
        createdAt: Date = Date(),
        cat: SupabaseFeedCat = .fixture(),
        owner: SupabaseFeedProfile = .fixture()
    ) -> SupabaseFeedRow {
        SupabaseFeedRow(
            id: id,
            ownerID: ownerID,
            catID: catID,
            date: date,
            locationName: locationName,
            locationLat: locationLat,
            locationLng: locationLng,
            notes: notes,
            photoUrls: photoUrls,
            likeCount: likeCount,
            commentCount: commentCount,
            createdAt: createdAt,
            cat: cat,
            owner: owner
        )
    }
}

extension SupabaseFeedCat {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Whiskers",
        breed: String? = "tabby",
        estimatedAge: String? = "2 years",
        locationName: String? = nil,
        locationLat: Double? = nil,
        locationLng: Double? = nil,
        notes: String? = nil,
        isOwned: Bool = false,
        photoUrls: [String] = [],
        createdAt: Date = Date()
    ) -> SupabaseFeedCat {
        SupabaseFeedCat(
            id: id,
            name: name,
            breed: breed,
            estimatedAge: estimatedAge,
            locationName: locationName,
            locationLat: locationLat,
            locationLng: locationLng,
            notes: notes,
            isOwned: isOwned,
            photoUrls: photoUrls,
            createdAt: createdAt
        )
    }
}

extension SupabaseFeedProfile {
    static func fixture(
        id: UUID = UUID(),
        displayName: String = "testuser",
        username: String = "testuser99",
        bio: String = "",
        isPrivate: Bool = false,
        avatarUrl: String? = nil
    ) -> SupabaseFeedProfile {
        SupabaseFeedProfile(
            id: id,
            displayName: displayName,
            username: username,
            bio: bio,
            isPrivate: isPrivate,
            avatarUrl: avatarUrl
        )
    }
}
