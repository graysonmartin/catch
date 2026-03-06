import XCTest
@testable import CatchCore

@MainActor
final class CKUserBrowseServiceBatchFetchTests: XCTestCase {

    private var sut: CKUserBrowseService!
    private var mockCloudKit: MockCloudKitService!
    private var mockCatRepo: MockCatRepository!
    private var mockEncounterRepo: MockEncounterRepository!
    private var mockFollowService: MockFollowService!

    override func setUp() {
        super.setUp()
        mockCloudKit = MockCloudKitService()
        mockCatRepo = MockCatRepository()
        mockEncounterRepo = MockEncounterRepository()
        mockFollowService = MockFollowService()
        sut = CKUserBrowseService(
            cloudKitService: mockCloudKit,
            catRepository: mockCatRepo,
            encounterRepository: mockEncounterRepo,
            followService: mockFollowService,
            currentUserIDProvider: { "current-user" }
        )
    }

    override func tearDown() {
        sut = nil
        mockCloudKit = nil
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
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "cool person",
            bio: "",
            isPrivate: false
        )

        _ = await sut.fetchDisplayName(userID: "user-1")

        XCTAssertEqual(sut.cachedDisplayName(for: "user-1"), "cool person")
    }

    // MARK: - batchFetchDisplayNames

    func testBatchFetchDisplayNamesReturnsAllNames() async {
        mockCloudKit.fetchResultsByUserID = [
            "user-1": CloudUserProfile(
                recordName: "rec-1",
                appleUserID: "user-1",
                displayName: "alice",
                bio: "",
                isPrivate: false
            ),
            "user-2": CloudUserProfile(
                recordName: "rec-2",
                appleUserID: "user-2",
                displayName: "bob",
                bio: "",
                isPrivate: false
            ),
            "user-3": CloudUserProfile(
                recordName: "rec-3",
                appleUserID: "user-3",
                displayName: "charlie",
                bio: "",
                isPrivate: false
            )
        ]

        let result = await sut.batchFetchDisplayNames(userIDs: ["user-1", "user-2", "user-3"])

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result["user-1"], "alice")
        XCTAssertEqual(result["user-2"], "bob")
        XCTAssertEqual(result["user-3"], "charlie")
    }

    func testBatchFetchDisplayNamesPopulatesCache() async {
        mockCloudKit.fetchResultsByUserID = [
            "user-1": CloudUserProfile(
                recordName: "rec-1",
                appleUserID: "user-1",
                displayName: "alice",
                bio: "",
                isPrivate: false
            ),
            "user-2": CloudUserProfile(
                recordName: "rec-2",
                appleUserID: "user-2",
                displayName: "bob",
                bio: "",
                isPrivate: false
            )
        ]

        _ = await sut.batchFetchDisplayNames(userIDs: ["user-1", "user-2"])

        XCTAssertEqual(sut.cachedDisplayName(for: "user-1"), "alice")
        XCTAssertEqual(sut.cachedDisplayName(for: "user-2"), "bob")
    }

    func testBatchFetchDisplayNamesSkipsCachedUsers() async {
        mockCloudKit.fetchResultsByUserID["user-1"] = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "alice",
            bio: "",
            isPrivate: false
        )
        _ = await sut.fetchDisplayName(userID: "user-1")
        mockCloudKit.fetchedAppleUserIDs.removeAll()

        mockCloudKit.fetchResultsByUserID["user-2"] = CloudUserProfile(
            recordName: "rec-2",
            appleUserID: "user-2",
            displayName: "bob",
            bio: "",
            isPrivate: false
        )

        let result = await sut.batchFetchDisplayNames(userIDs: ["user-1", "user-2"])

        XCTAssertEqual(mockCloudKit.fetchedAppleUserIDs, ["user-2"])
        XCTAssertEqual(result["user-1"], "alice")
        XCTAssertEqual(result["user-2"], "bob")
    }

    func testBatchFetchDisplayNamesHandlesNotFoundUsers() async {
        mockCloudKit.fetchResultsByUserID = [
            "user-1": CloudUserProfile(
                recordName: "rec-1",
                appleUserID: "user-1",
                displayName: "alice",
                bio: "",
                isPrivate: false
            )
        ]

        let result = await sut.batchFetchDisplayNames(userIDs: ["user-1", "user-2"])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["user-1"], "alice")
        XCTAssertNil(result["user-2"])
    }

    func testBatchFetchDisplayNamesWithEmptyArrayReturnsEmpty() async {
        let result = await sut.batchFetchDisplayNames(userIDs: [])

        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockCloudKit.fetchedAppleUserIDs.isEmpty)
    }

    func testBatchFetchDisplayNamesAllCachedSkipsNetwork() async {
        mockCloudKit.fetchResultsByUserID["user-1"] = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "alice",
            bio: "",
            isPrivate: false
        )
        mockCloudKit.fetchResultsByUserID["user-2"] = CloudUserProfile(
            recordName: "rec-2",
            appleUserID: "user-2",
            displayName: "bob",
            bio: "",
            isPrivate: false
        )
        _ = await sut.fetchDisplayName(userID: "user-1")
        _ = await sut.fetchDisplayName(userID: "user-2")
        mockCloudKit.fetchedAppleUserIDs.removeAll()

        let result = await sut.batchFetchDisplayNames(userIDs: ["user-1", "user-2"])

        XCTAssertTrue(mockCloudKit.fetchedAppleUserIDs.isEmpty)
        XCTAssertEqual(result["user-1"], "alice")
        XCTAssertEqual(result["user-2"], "bob")
    }

    func testBatchFetchedNamesAvailableViaFetchDisplayName() async {
        mockCloudKit.fetchResultsByUserID = [
            "user-1": CloudUserProfile(
                recordName: "rec-1",
                appleUserID: "user-1",
                displayName: "alice",
                bio: "",
                isPrivate: false
            )
        ]

        _ = await sut.batchFetchDisplayNames(userIDs: ["user-1"])
        mockCloudKit.fetchedAppleUserIDs.removeAll()

        let name = await sut.fetchDisplayName(userID: "user-1")

        XCTAssertEqual(name, "alice")
        XCTAssertTrue(mockCloudKit.fetchedAppleUserIDs.isEmpty, "should use cache, not fetch again")
    }
}
