import XCTest
import CatchCore

@MainActor
final class CKSocialFeedServicePaginationTests: XCTestCase {
    private var sut: CKSocialFeedService!
    private var mockFollowService: MockFollowService!
    private var mockBrowseService: MockUserBrowseService!

    override func setUp() {
        super.setUp()
        mockFollowService = MockFollowService()
        mockBrowseService = MockUserBrowseService()
        sut = CKSocialFeedService(
            followService: mockFollowService,
            userBrowseService: mockBrowseService,
            currentUserIDProvider: { nil }
        )
    }

    override func tearDown() {
        sut = nil
        mockFollowService = nil
        mockBrowseService = nil
        super.tearDown()
    }

    // MARK: - Pagination Page Size

    func testRefreshLimitsToDefaultPageSize() async {
        // Use 3 users with 10 encounters each = 30 total, exceeding page size of 20
        for userIndex in 0..<3 {
            let userID = "user-\(userIndex)"
            mockFollowService.simulateFollowing(followeeID: userID)

            let profile = makeProfile(userID: userID, name: "user\(userIndex)")
            let cat = makeCat(recordName: "cat-\(userIndex)", ownerID: userID, name: "Cat\(userIndex)")
            let encounters = (0..<10).map { i in
                makeEncounter(
                    recordName: "enc-\(userIndex)-\(i)",
                    ownerID: userID,
                    catRecordName: "cat-\(userIndex)",
                    daysAgo: i
                )
            }

            mockBrowseService.fetchUserDataResults[userID] = .success(
                UserBrowseData(
                    profile: profile, cats: [cat], encounters: encounters,
                    followerCount: 0, followingCount: 0, fetchedAt: Date()
                )
            )
        }

        await sut.refresh()

        // Should only show 20 items initially (defaultPageSize), not all 30
        XCTAssertEqual(sut.remoteEncounters.count, 20)
        XCTAssertTrue(sut.hasMorePages)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Load More

    func testLoadMoreAppendsNextPage() async {
        // Use 3 users with 10 encounters each = 30 total
        for userIndex in 0..<3 {
            let userID = "user-\(userIndex)"
            mockFollowService.simulateFollowing(followeeID: userID)

            let profile = makeProfile(userID: userID, name: "user\(userIndex)")
            let cat = makeCat(recordName: "cat-\(userIndex)", ownerID: userID, name: "Cat\(userIndex)")
            let encounters = (0..<10).map { i in
                makeEncounter(
                    recordName: "enc-\(userIndex)-\(i)",
                    ownerID: userID,
                    catRecordName: "cat-\(userIndex)",
                    daysAgo: i
                )
            }

            mockBrowseService.fetchUserDataResults[userID] = .success(
                UserBrowseData(
                    profile: profile, cats: [cat], encounters: encounters,
                    followerCount: 0, followingCount: 0, fetchedAt: Date()
                )
            )
        }

        await sut.refresh()
        XCTAssertEqual(sut.remoteEncounters.count, 20)
        XCTAssertTrue(sut.hasMorePages)

        await sut.loadMore()

        // All 30 items now shown
        XCTAssertEqual(sut.remoteEncounters.count, 30)
        XCTAssertFalse(sut.hasMorePages)
    }

    func testLoadMoreWithMultipleUsersShowsAll() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")
        mockFollowService.simulateFollowing(followeeID: "user-b")

        let profileA = makeProfile(userID: "user-a", name: "alice")
        let catA = makeCat(recordName: "cat-a", ownerID: "user-a", name: "Whiskers")
        let encountersA = (0..<15).map { i in
            makeEncounter(recordName: "enc-a\(i)", ownerID: "user-a", catRecordName: "cat-a", daysAgo: i)
        }

        let profileB = makeProfile(userID: "user-b", name: "bob")
        let catB = makeCat(recordName: "cat-b", ownerID: "user-b", name: "Mittens")
        let encountersB = (0..<15).map { i in
            makeEncounter(recordName: "enc-b\(i)", ownerID: "user-b", catRecordName: "cat-b", daysAgo: i)
        }

        mockBrowseService.fetchUserDataResults["user-a"] = .success(
            UserBrowseData(profile: profileA, cats: [catA], encounters: encountersA, followerCount: 0, followingCount: 0, fetchedAt: Date())
        )
        mockBrowseService.fetchUserDataResults["user-b"] = .success(
            UserBrowseData(profile: profileB, cats: [catB], encounters: encountersB, followerCount: 0, followingCount: 0, fetchedAt: Date())
        )

        await sut.refresh()
        XCTAssertEqual(sut.remoteEncounters.count, 20)
        XCTAssertTrue(sut.hasMorePages)

        await sut.loadMore()
        XCTAssertEqual(sut.remoteEncounters.count, 30)
        XCTAssertFalse(sut.hasMorePages)
    }

    // MARK: - No More Pages

    func testRefreshWithFewItemsHasNoMorePages() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")

        let profile = makeProfile(userID: "user-a", name: "alice")
        let cat = makeCat(recordName: "cat-a", ownerID: "user-a", name: "Whiskers")
        let encounter = makeEncounter(recordName: "enc-a1", ownerID: "user-a", catRecordName: "cat-a")

        mockBrowseService.fetchUserDataResults["user-a"] = .success(
            UserBrowseData(
                profile: profile,
                cats: [cat],
                encounters: [encounter],
                followerCount: 0,
                followingCount: 0,
                fetchedAt: Date()
            )
        )

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 1)
        XCTAssertFalse(sut.hasMorePages)
    }

    // MARK: - Loading State

    func testLoadMoreSetsLoadingState() async {
        // Use 2 users with 15 encounters each = 30 total
        for userIndex in 0..<2 {
            let userID = "user-\(userIndex)"
            mockFollowService.simulateFollowing(followeeID: userID)
            let profile = makeProfile(userID: userID, name: "user\(userIndex)")
            let cat = makeCat(recordName: "cat-\(userIndex)", ownerID: userID, name: "Cat\(userIndex)")
            let encounters = (0..<15).map { i in
                makeEncounter(recordName: "enc-\(userIndex)-\(i)", ownerID: userID, catRecordName: "cat-\(userIndex)", daysAgo: i)
            }
            mockBrowseService.fetchUserDataResults[userID] = .success(
                UserBrowseData(profile: profile, cats: [cat], encounters: encounters, followerCount: 0, followingCount: 0, fetchedAt: Date())
            )
        }

        await sut.refresh()

        // isLoadingMore should be false after load completes
        XCTAssertFalse(sut.isLoadingMore)

        await sut.loadMore()
        XCTAssertFalse(sut.isLoadingMore)
    }

    // MARK: - Refresh Resets Pagination

    func testRefreshResetsPagination() async {
        // Use 2 users with 15 encounters each = 30 total
        for userIndex in 0..<2 {
            let userID = "user-\(userIndex)"
            mockFollowService.simulateFollowing(followeeID: userID)
            let profile = makeProfile(userID: userID, name: "user\(userIndex)")
            let cat = makeCat(recordName: "cat-\(userIndex)", ownerID: userID, name: "Cat\(userIndex)")
            let encounters = (0..<15).map { i in
                makeEncounter(recordName: "enc-\(userIndex)-\(i)", ownerID: userID, catRecordName: "cat-\(userIndex)", daysAgo: i)
            }
            mockBrowseService.fetchUserDataResults[userID] = .success(
                UserBrowseData(profile: profile, cats: [cat], encounters: encounters, followerCount: 0, followingCount: 0, fetchedAt: Date())
            )
        }

        await sut.refresh()
        XCTAssertEqual(sut.remoteEncounters.count, 20)
        XCTAssertTrue(sut.hasMorePages)

        await sut.loadMore()
        XCTAssertEqual(sut.remoteEncounters.count, 30)

        // Refresh again should reset to first page
        await sut.refresh()
        XCTAssertEqual(sut.remoteEncounters.count, 20)
        XCTAssertTrue(sut.hasMorePages)
    }

    // MARK: - Empty Following

    func testRefreshWithEmptyFollowingClearsPagination() async {
        await sut.refresh()

        XCTAssertTrue(sut.remoteEncounters.isEmpty)
        XCTAssertFalse(sut.hasMorePages)
    }

    // MARK: - Feed Sorted By Date

    func testFeedItemsSortedByDateDescending() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")
        mockFollowService.simulateFollowing(followeeID: "user-b")

        let profileA = makeProfile(userID: "user-a", name: "alice")
        let catA = makeCat(recordName: "cat-a", ownerID: "user-a", name: "A")
        let encounterA = makeEncounter(recordName: "enc-old", ownerID: "user-a", catRecordName: "cat-a", daysAgo: 10)

        let profileB = makeProfile(userID: "user-b", name: "bob")
        let catB = makeCat(recordName: "cat-b", ownerID: "user-b", name: "B")
        let encounterB = makeEncounter(recordName: "enc-new", ownerID: "user-b", catRecordName: "cat-b", daysAgo: 1)

        mockBrowseService.fetchUserDataResults["user-a"] = .success(
            UserBrowseData(profile: profileA, cats: [catA], encounters: [encounterA], followerCount: 0, followingCount: 0, fetchedAt: Date())
        )
        mockBrowseService.fetchUserDataResults["user-b"] = .success(
            UserBrowseData(profile: profileB, cats: [catB], encounters: [encounterB], followerCount: 0, followingCount: 0, fetchedAt: Date())
        )

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 2)
        // Most recent should be first
        XCTAssertEqual(sut.remoteEncounters.first?.id, "remote-enc-new")
        XCTAssertEqual(sut.remoteEncounters.last?.id, "remote-enc-old")
    }

    // MARK: - Helpers

    private func makeProfile(userID: String, name: String) -> CloudUserProfile {
        CloudUserProfile(
            recordName: "profile-\(userID)",
            appleUserID: userID,
            displayName: name,
            bio: "",
            username: name,
            isPrivate: false
        )
    }

    private func makeCat(recordName: String, ownerID: String, name: String) -> CloudCat {
        CloudCat(
            recordName: recordName,
            ownerID: ownerID,
            name: name,
            breed: "",
            estimatedAge: "",
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: false,
            createdAt: Date(),
            photos: []
        )
    }

    private func makeEncounter(
        recordName: String,
        ownerID: String,
        catRecordName: String,
        daysAgo: Int = 0
    ) -> CloudEncounter {
        CloudEncounter(
            recordName: recordName,
            ownerID: ownerID,
            catRecordName: catRecordName,
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            photos: []
        )
    }
}
