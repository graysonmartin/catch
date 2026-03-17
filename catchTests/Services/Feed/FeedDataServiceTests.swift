import XCTest
import CatchCore

@MainActor
final class FeedDataServiceTests: XCTestCase {
    private var sut: FeedDataService!
    private var mockRepo: MockSupabaseEncounterRepository!
    private let testUserID = "user-123"

    override func setUp() {
        super.setUp()
        mockRepo = MockSupabaseEncounterRepository()
        sut = FeedDataService(
            encounterRepository: mockRepo,
            getUserID: { [testUserID] in testUserID },
            pageSize: 3
        )
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        super.tearDown()
    }

    // MARK: - Refresh

    func testRefreshFetchesFirstPage() async {
        let catID = UUID()
        mockRepo.fetchEncounterFeedResult = [
            .fixture(catID: catID, date: Date())
        ]

        await sut.refresh()

        XCTAssertEqual(sut.encounters.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(mockRepo.fetchEncounterFeedCalls.count, 1)

        let call = mockRepo.fetchEncounterFeedCalls[0]
        XCTAssertEqual(call.ownerID, testUserID)
        XCTAssertEqual(call.limit, 3)
        XCTAssertNil(call.cursor)
    }

    func testRefreshWithNoUserIDDoesNothing() async {
        sut = FeedDataService(
            encounterRepository: mockRepo,
            getUserID: { nil },
            pageSize: 3
        )

        await sut.refresh()

        XCTAssertTrue(sut.encounters.isEmpty)
        XCTAssertTrue(mockRepo.fetchEncounterFeedCalls.isEmpty)
    }

    func testRefreshResetsStateOnError() async {
        // First load some data
        mockRepo.fetchEncounterFeedResult = [.fixture(), .fixture(), .fixture()]
        await sut.refresh()
        XCTAssertEqual(sut.encounters.count, 3)

        // Now simulate an error on refresh
        mockRepo.errorToThrow = NSError(domain: "test", code: 1)
        await sut.refresh()

        XCTAssertTrue(sut.encounters.isEmpty)
        XCTAssertFalse(sut.hasMorePages)
    }

    func testRefreshResetsCursor() async {
        // Load a full page to set hasMorePages
        mockRepo.fetchEncounterFeedResult = [.fixture(), .fixture(), .fixture()]
        await sut.refresh()
        XCTAssertTrue(sut.hasMorePages)

        // Refresh again — should pass nil cursor
        mockRepo.fetchEncounterFeedResult = [.fixture()]
        await sut.refresh()

        XCTAssertEqual(mockRepo.fetchEncounterFeedCalls.count, 2)
        XCTAssertNil(mockRepo.fetchEncounterFeedCalls[1].cursor)
        XCTAssertEqual(sut.encounters.count, 1)
        XCTAssertFalse(sut.hasMorePages)
    }

    // MARK: - Pagination

    func testHasMorePagesWhenFullPageReturned() async {
        mockRepo.fetchEncounterFeedResult = [.fixture(), .fixture(), .fixture()]
        await sut.refresh()

        XCTAssertTrue(sut.hasMorePages)
    }

    func testNoMorePagesWhenPartialPageReturned() async {
        mockRepo.fetchEncounterFeedResult = [.fixture(), .fixture()]
        await sut.refresh()

        XCTAssertFalse(sut.hasMorePages)
    }

    func testLoadMoreAppendsEncounters() async {
        let now = Date()
        let page1 = (0..<3).map { i in
            SupabaseEncounterFeedRow.fixture(
                date: now.addingTimeInterval(Double(-i * 60))
            )
        }
        let page2 = (3..<5).map { i in
            SupabaseEncounterFeedRow.fixture(
                date: now.addingTimeInterval(Double(-i * 60))
            )
        }

        let cursor1 = ISO8601DateFormatter().string(from: page1.last!.date)
        mockRepo.fetchEncounterFeedResultsByCursor = [
            nil: page1,
            cursor1: page2
        ]

        await sut.refresh()
        XCTAssertEqual(sut.encounters.count, 3)
        XCTAssertTrue(sut.hasMorePages)

        await sut.loadMore()
        XCTAssertEqual(sut.encounters.count, 5)
        XCTAssertFalse(sut.hasMorePages)
    }

    func testLoadMorePassesCursorFromLastItem() async {
        let now = Date()
        let page1 = (0..<3).map { i in
            SupabaseEncounterFeedRow.fixture(
                date: now.addingTimeInterval(Double(-i * 60))
            )
        }

        mockRepo.fetchEncounterFeedResult = page1
        await sut.refresh()

        // Setup empty next page
        mockRepo.fetchEncounterFeedResult = []
        await sut.loadMore()

        XCTAssertEqual(mockRepo.fetchEncounterFeedCalls.count, 2)
        let loadMoreCall = mockRepo.fetchEncounterFeedCalls[1]
        let expectedCursor = ISO8601DateFormatter().string(from: page1.last!.date)
        XCTAssertEqual(loadMoreCall.cursor, expectedCursor)
    }

    func testLoadMoreDoesNothingWhenNoMorePages() async {
        mockRepo.fetchEncounterFeedResult = [.fixture()]
        await sut.refresh()
        XCTAssertFalse(sut.hasMorePages)

        await sut.loadMore()
        XCTAssertEqual(mockRepo.fetchEncounterFeedCalls.count, 1)
    }

    func testLoadMoreSetsHasMorePagesToFalseOnError() async {
        mockRepo.fetchEncounterFeedResult = [.fixture(), .fixture(), .fixture()]
        await sut.refresh()
        XCTAssertTrue(sut.hasMorePages)

        mockRepo.errorToThrow = NSError(domain: "test", code: 1)
        await sut.loadMore()

        XCTAssertFalse(sut.hasMorePages)
        // Existing encounters preserved on loadMore error
        XCTAssertEqual(sut.encounters.count, 3)
    }

    // MARK: - Mapping

    func testEncountersMappedWithCatData() async {
        let catID = UUID()
        let cat = SupabaseFeedCat(
            id: catID,
            name: "Whiskers",
            breed: "tabby",
            estimatedAge: nil,
            locationName: "park",
            locationLat: 37.7,
            locationLng: -122.4,
            notes: nil,
            isOwned: true,
            photoUrls: ["url1"],
            createdAt: Date()
        )

        mockRepo.fetchEncounterFeedResult = [
            .fixture(catID: catID, notes: "spotted near tree", cat: cat)
        ]

        await sut.refresh()

        XCTAssertEqual(sut.encounters.count, 1)
        let encounter = sut.encounters[0]
        XCTAssertEqual(encounter.notes, "spotted near tree")
        XCTAssertEqual(encounter.cat?.name, "Whiskers")
        XCTAssertEqual(encounter.cat?.breed, "tabby")
        XCTAssertEqual(encounter.cat?.isOwned, true)
        XCTAssertEqual(encounter.catID, catID)
    }

    // MARK: - Mutation Support

    func testPrependEncounter() async {
        mockRepo.fetchEncounterFeedResult = [.fixture()]
        await sut.refresh()
        XCTAssertEqual(sut.encounters.count, 1)

        let newEncounter = Encounter(id: UUID(), date: Date(), notes: "new one")
        sut.prependEncounter(newEncounter)

        XCTAssertEqual(sut.encounters.count, 2)
        XCTAssertEqual(sut.encounters[0].id, newEncounter.id)
    }

    func testRemoveEncounter() async {
        let id1 = UUID()
        let id2 = UUID()
        mockRepo.fetchEncounterFeedResult = [
            .fixture(id: id1),
            .fixture(id: id2)
        ]
        await sut.refresh()
        XCTAssertEqual(sut.encounters.count, 2)

        sut.removeEncounter(id: id1)

        XCTAssertEqual(sut.encounters.count, 1)
        XCTAssertEqual(sut.encounters[0].id, id2)
    }

    func testRemoveNonexistentEncounterDoesNothing() async {
        mockRepo.fetchEncounterFeedResult = [.fixture()]
        await sut.refresh()

        sut.removeEncounter(id: UUID())

        XCTAssertEqual(sut.encounters.count, 1)
    }
}

// MARK: - Fixtures

extension SupabaseEncounterFeedRow {
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
        cat: SupabaseFeedCat? = nil
    ) -> SupabaseEncounterFeedRow {
        SupabaseEncounterFeedRow(
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
            cat: cat ?? SupabaseFeedCat(
                id: catID,
                name: "Test Cat",
                breed: nil,
                estimatedAge: nil,
                locationName: locationName,
                locationLat: locationLat,
                locationLng: locationLng,
                notes: nil,
                isOwned: false,
                photoUrls: [],
                createdAt: createdAt
            )
        )
    }
}
