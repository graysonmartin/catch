import XCTest
@testable import CatchCore

@MainActor
final class SupabaseUserBrowseServiceBatchFetchTests: XCTestCase {

    private var sut: SupabaseUserBrowseService!
    private var mockProfileRepo: MockSupabaseProfileRepository!
    private var mockCatRepo: MockCatRepository!
    private var mockEncounterRepo: MockEncounterRepository!
    private var mockFollowService: MockFollowService!

    override func setUp() {
        super.setUp()
        mockProfileRepo = MockSupabaseProfileRepository()
        mockCatRepo = MockCatRepository()
        mockEncounterRepo = MockEncounterRepository()
        mockFollowService = MockFollowService()
        sut = SupabaseUserBrowseService(
            profileRepository: mockProfileRepo,
            catRepository: mockCatRepo,
            encounterRepository: mockEncounterRepo,
            followService: mockFollowService,
            currentUserIDProvider: { "current-user" }
        )
    }

    override func tearDown() {
        sut = nil
        mockProfileRepo = nil
        mockCatRepo = nil
        mockEncounterRepo = nil
        mockFollowService = nil
        super.tearDown()
    }

    // MARK: - cachedDisplayName

    func testCachedDisplayNameReturnsNilBeforeFetch() {
        XCTAssertNil(sut.cachedDisplayName(for: "user-1"))
    }

    func testCachedDisplayNameReturnsCachedValueAfterFetch() async {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = .fixture(id: userID, displayName: "cool person")

        _ = await sut.fetchDisplayName(userID: userID.uuidString.lowercased())

        XCTAssertEqual(sut.cachedDisplayName(for: userID.uuidString.lowercased()), "cool person")
    }

    // MARK: - batchFetchDisplayNames

    func testBatchFetchDisplayNamesReturnsAllNames() async {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        mockProfileRepo.fetchProfilesResult = [
            .fixture(id: id1, displayName: "alice"),
            .fixture(id: id2, displayName: "bob"),
            .fixture(id: id3, displayName: "charlie")
        ]

        let result = await sut.batchFetchDisplayNames(userIDs: [id1.uuidString.lowercased(), id2.uuidString.lowercased(), id3.uuidString.lowercased()])

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[id1.uuidString.lowercased()], "alice")
        XCTAssertEqual(result[id2.uuidString.lowercased()], "bob")
        XCTAssertEqual(result[id3.uuidString.lowercased()], "charlie")
    }

    func testBatchFetchDisplayNamesPopulatesCache() async {
        let id1 = UUID()
        let id2 = UUID()
        mockProfileRepo.fetchProfilesResult = [
            .fixture(id: id1, displayName: "alice"),
            .fixture(id: id2, displayName: "bob")
        ]

        _ = await sut.batchFetchDisplayNames(userIDs: [id1.uuidString.lowercased(), id2.uuidString.lowercased()])

        XCTAssertEqual(sut.cachedDisplayName(for: id1.uuidString.lowercased()), "alice")
        XCTAssertEqual(sut.cachedDisplayName(for: id2.uuidString.lowercased()), "bob")
    }

    func testBatchFetchDisplayNamesSkipsCachedUsers() async {
        let id1 = UUID()
        let id2 = UUID()
        mockProfileRepo.fetchProfileResult = .fixture(id: id1, displayName: "alice")
        _ = await sut.fetchDisplayName(userID: id1.uuidString.lowercased())
        mockProfileRepo.fetchProfileCalls.removeAll()

        mockProfileRepo.fetchProfilesResult = [
            .fixture(id: id2, displayName: "bob")
        ]

        let result = await sut.batchFetchDisplayNames(userIDs: [id1.uuidString.lowercased(), id2.uuidString.lowercased()])

        XCTAssertEqual(mockProfileRepo.fetchProfilesCalls.count, 1)
        XCTAssertEqual(mockProfileRepo.fetchProfilesCalls.first, [id2.uuidString.lowercased()], "should only fetch uncached user")
        XCTAssertEqual(result[id1.uuidString.lowercased()], "alice")
        XCTAssertEqual(result[id2.uuidString.lowercased()], "bob")
    }

    func testBatchFetchDisplayNamesHandlesNotFoundUsers() async {
        let id1 = UUID()
        let id2 = UUID()
        mockProfileRepo.fetchProfilesResult = [
            .fixture(id: id1, displayName: "alice")
        ]

        let result = await sut.batchFetchDisplayNames(userIDs: [id1.uuidString.lowercased(), id2.uuidString.lowercased()])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[id1.uuidString.lowercased()], "alice")
        XCTAssertNil(result[id2.uuidString.lowercased()])
    }

    func testBatchFetchDisplayNamesWithEmptyArrayReturnsEmpty() async {
        let result = await sut.batchFetchDisplayNames(userIDs: [])

        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockProfileRepo.fetchProfilesCalls.isEmpty)
    }

    func testBatchFetchDisplayNamesAllCachedSkipsNetwork() async {
        let id1 = UUID()
        let id2 = UUID()
        mockProfileRepo.fetchProfileResultsByID[id1.uuidString.lowercased()] = .fixture(id: id1, displayName: "alice")
        mockProfileRepo.fetchProfileResultsByID[id2.uuidString.lowercased()] = .fixture(id: id2, displayName: "bob")
        _ = await sut.fetchDisplayName(userID: id1.uuidString.lowercased())
        _ = await sut.fetchDisplayName(userID: id2.uuidString.lowercased())
        mockProfileRepo.fetchProfileCalls.removeAll()

        let result = await sut.batchFetchDisplayNames(userIDs: [id1.uuidString.lowercased(), id2.uuidString.lowercased()])

        XCTAssertTrue(mockProfileRepo.fetchProfilesCalls.isEmpty, "should not batch fetch when all cached")
        XCTAssertEqual(result[id1.uuidString.lowercased()], "alice")
        XCTAssertEqual(result[id2.uuidString.lowercased()], "bob")
    }

    func testBatchFetchedNamesAvailableViaFetchDisplayName() async {
        let id1 = UUID()
        mockProfileRepo.fetchProfilesResult = [
            .fixture(id: id1, displayName: "alice")
        ]

        _ = await sut.batchFetchDisplayNames(userIDs: [id1.uuidString.lowercased()])
        mockProfileRepo.fetchProfileCalls.removeAll()
        mockProfileRepo.fetchProfilesCalls.removeAll()

        let name = await sut.fetchDisplayName(userID: id1.uuidString.lowercased())

        XCTAssertEqual(name, "alice")
        XCTAssertTrue(mockProfileRepo.fetchProfileCalls.isEmpty, "should use cache, not fetch again")
    }

    func testBatchFetchUsesSingleQuery() async {
        let ids = (0..<5).map { _ in UUID() }
        mockProfileRepo.fetchProfilesResult = ids.enumerated().map { i, id in
            .fixture(id: id, displayName: "user-\(i)")
        }

        _ = await sut.batchFetchDisplayNames(userIDs: ids.map { $0.uuidString.lowercased() })

        XCTAssertEqual(mockProfileRepo.fetchProfilesCalls.count, 1, "should use single batch query, not N individual fetches")
    }

}
