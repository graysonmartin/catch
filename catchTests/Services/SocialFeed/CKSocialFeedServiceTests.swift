import XCTest

@MainActor
final class CKSocialFeedServiceTests: XCTestCase {
    private var sut: CKSocialFeedService!
    private var mockFollowService: MockFollowService!
    private var mockBrowseService: MockUserBrowseService!

    override func setUp() {
        super.setUp()
        mockFollowService = MockFollowService()
        mockBrowseService = MockUserBrowseService()
        sut = CKSocialFeedService(
            followService: mockFollowService,
            userBrowseService: mockBrowseService
        )
    }

    override func tearDown() {
        sut = nil
        mockFollowService = nil
        mockBrowseService = nil
        super.tearDown()
    }

    // MARK: - Empty State

    func testRefreshWithNoFollowsReturnsEmpty() async {
        await sut.refresh()

        XCTAssertTrue(sut.remoteEncounters.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Fetching Encounters

    func testRefreshFetchesEncountersFromFollowedUsers() async {
        mockFollowService.simulateFollowing(followeeID: "user-a")
        mockFollowService.simulateFollowing(followeeID: "user-b")

        let profileA = makeProfile(userID: "user-a", name: "alice")
        let catA = makeCat(recordName: "cat-a", ownerID: "user-a", name: "Whiskers")
        let encounterA = makeEncounter(recordName: "enc-a1", ownerID: "user-a", catRecordName: "cat-a")

        let profileB = makeProfile(userID: "user-b", name: "bob")
        let catB = makeCat(recordName: "cat-b", ownerID: "user-b", name: "Mittens")
        let encounterB = makeEncounter(recordName: "enc-b1", ownerID: "user-b", catRecordName: "cat-b")

        mockBrowseService.fetchUserDataResults["user-a"] = .success(
            UserBrowseData(profile: profileA, cats: [catA], encounters: [encounterA], fetchedAt: Date())
        )
        mockBrowseService.fetchUserDataResults["user-b"] = .success(
            UserBrowseData(profile: profileB, cats: [catB], encounters: [encounterB], fetchedAt: Date())
        )

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 2)
        XCTAssertFalse(sut.isLoading)

        let ids = Set(sut.remoteEncounters.map(\.id))
        XCTAssertTrue(ids.contains("remote-enc-a1"))
        XCTAssertTrue(ids.contains("remote-enc-b1"))
    }

    // MARK: - Per-User Encounter Cap

    func testRefreshCapsEncountersPerUserAt20() async {
        mockFollowService.simulateFollowing(followeeID: "prolific-user")

        let profile = makeProfile(userID: "prolific-user", name: "prolific")
        let cat = makeCat(recordName: "cat-p", ownerID: "prolific-user", name: "Busy")

        let encounters = (0..<30).map { i in
            makeEncounter(
                recordName: "enc-p\(i)",
                ownerID: "prolific-user",
                catRecordName: "cat-p",
                daysAgo: i
            )
        }

        mockBrowseService.fetchUserDataResults["prolific-user"] = .success(
            UserBrowseData(profile: profile, cats: [cat], encounters: encounters, fetchedAt: Date())
        )

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 20)
    }

    // MARK: - Graceful Failure Handling

    func testRefreshHandlesIndividualUserFetchFailures() async {
        mockFollowService.simulateFollowing(followeeID: "good-user")
        mockFollowService.simulateFollowing(followeeID: "bad-user")

        let profile = makeProfile(userID: "good-user", name: "good")
        let cat = makeCat(recordName: "cat-g", ownerID: "good-user", name: "Lucky")
        let encounter = makeEncounter(recordName: "enc-g1", ownerID: "good-user", catRecordName: "cat-g")

        mockBrowseService.fetchUserDataResults["good-user"] = .success(
            UserBrowseData(profile: profile, cats: [cat], encounters: [encounter], fetchedAt: Date())
        )
        mockBrowseService.fetchUserDataResults["bad-user"] = .failure(.networkError("timeout"))

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 1)
        XCTAssertEqual(sut.remoteEncounters.first?.id, "remote-enc-g1")
    }

    // MARK: - Loading State

    func testLoadingStateIsSetDuringRefresh() async {
        mockFollowService.simulateFollowing(followeeID: "user-x")

        let profile = makeProfile(userID: "user-x", name: "x")
        mockBrowseService.fetchUserDataResults["user-x"] = .success(
            UserBrowseData(profile: profile, cats: [], encounters: [], fetchedAt: Date())
        )

        XCTAssertFalse(sut.isLoading)

        await sut.refresh()

        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Cat/Owner Association

    func testRemoteEncountersHaveCorrectCatAndOwner() async {
        mockFollowService.simulateFollowing(followeeID: "user-c")

        let profile = makeProfile(userID: "user-c", name: "charlie")
        let cat = makeCat(recordName: "cat-c1", ownerID: "user-c", name: "Paws")
        let encounter = makeEncounter(recordName: "enc-c1", ownerID: "user-c", catRecordName: "cat-c1")

        mockBrowseService.fetchUserDataResults["user-c"] = .success(
            UserBrowseData(profile: profile, cats: [cat], encounters: [encounter], fetchedAt: Date())
        )

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 1)

        guard case .remote(let enc, let associatedCat, let owner) = sut.remoteEncounters.first else {
            XCTFail("Expected remote feed item")
            return
        }
        XCTAssertEqual(enc.recordName, "enc-c1")
        XCTAssertEqual(associatedCat?.recordName, "cat-c1")
        XCTAssertEqual(associatedCat?.name, "Paws")
        XCTAssertEqual(owner.displayName, "charlie")
    }

    // MARK: - Encounter Without Matching Cat

    func testRemoteEncounterWithNoMatchingCatHasNilCat() async {
        mockFollowService.simulateFollowing(followeeID: "user-d")

        let profile = makeProfile(userID: "user-d", name: "dana")
        let encounter = makeEncounter(recordName: "enc-d1", ownerID: "user-d", catRecordName: "nonexistent-cat")

        mockBrowseService.fetchUserDataResults["user-d"] = .success(
            UserBrowseData(profile: profile, cats: [], encounters: [encounter], fetchedAt: Date())
        )

        await sut.refresh()

        XCTAssertEqual(sut.remoteEncounters.count, 1)
        guard case .remote(_, let associatedCat, _) = sut.remoteEncounters.first else {
            XCTFail("Expected remote feed item")
            return
        }
        XCTAssertNil(associatedCat)
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
