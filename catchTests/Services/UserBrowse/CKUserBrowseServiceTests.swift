import XCTest

@MainActor
final class CKUserBrowseServiceTests: XCTestCase {

    private var sut: CKUserBrowseService!
    private var mockCloudKit: MockCloudKitService!
    private var mockCatRepo: MockCatRepository!
    private var mockEncounterRepo: MockEncounterRepository!
    private var mockFollowService: MockFollowService!
    private var currentUserID: String?

    override func setUp() {
        super.setUp()
        mockCloudKit = MockCloudKitService()
        mockCatRepo = MockCatRepository()
        mockEncounterRepo = MockEncounterRepository()
        mockFollowService = MockFollowService()
        currentUserID = "current-user"
        sut = CKUserBrowseService(
            cloudKitService: mockCloudKit,
            catRepository: mockCatRepo,
            encounterRepository: mockEncounterRepo,
            followService: mockFollowService,
            currentUserIDProvider: { [weak self] in self?.currentUserID }
        )
    }

    override func tearDown() {
        sut = nil
        mockCloudKit = nil
        mockCatRepo = nil
        mockEncounterRepo = nil
        mockFollowService = nil
        currentUserID = nil
        super.tearDown()
    }

    // MARK: - fetchUserData

    func testFetchUserDataReturnsProfileAndData() async throws {
        let profile = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "cat lord",
            bio: "i pet cats",
            isPrivate: false
        )
        mockCloudKit.fetchResult = profile

        let cat = CloudCat(
            recordName: "cat-1",
            ownerID: "user-1",
            name: "Muffin",
            breed: "",
            estimatedAge: "3",
            locationName: "park",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: false,
            createdAt: Date(),
            photos: []
        )
        mockCatRepo.fetchAllResult = [cat]

        let encounter = CloudEncounter(
            recordName: "enc-1",
            ownerID: "user-1",
            catRecordName: "cat-1",
            date: Date(),
            locationName: "park",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "spotted",
            photos: []
        )
        mockEncounterRepo.fetchAllResult = [encounter]

        let data = try await sut.fetchUserData(userID: "user-1")

        XCTAssertEqual(data.profile.displayName, "cat lord")
        XCTAssertEqual(data.cats.count, 1)
        XCTAssertEqual(data.cats.first?.name, "Muffin")
        XCTAssertEqual(data.encounters.count, 1)
        XCTAssertEqual(data.encounters.first?.notes, "spotted")
        XCTAssertFalse(data.isExpired)
    }

    func testFetchUserDataThrowsUserNotFoundWhenNoProfile() async {
        mockCloudKit.fetchResult = nil

        do {
            _ = try await sut.fetchUserData(userID: "ghost")
            XCTFail("expected userNotFound error")
        } catch let error as UserBrowseError {
            XCTAssertEqual(error, .userNotFound)
        } catch {
            XCTFail("unexpected error: \(error)")
        }

        XCTAssertEqual(sut.error, .userNotFound)
    }

    func testFetchUserDataThrowsNetworkErrorOnRepoFailure() async {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "test",
            bio: "",
            isPrivate: false
        )
        mockCatRepo.fetchAllError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])

        do {
            _ = try await sut.fetchUserData(userID: "user-1")
            XCTFail("expected networkError")
        } catch let error as UserBrowseError {
            if case .networkError = error {
                // expected
            } else {
                XCTFail("expected networkError, got \(error)")
            }
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    // MARK: - Privacy enforcement

    func testPrivateProfileReturnsEmptyDataWhenNotFollowing() async throws {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-priv",
            appleUserID: "private-user",
            displayName: "shiv",
            bio: "none of your business",
            isPrivate: true
        )
        mockCatRepo.fetchAllResult = [
            CloudCat(
                recordName: "cat-hidden",
                ownerID: "private-user",
                name: "Ghost",
                breed: "",
                estimatedAge: "?",
                locationName: "classified",
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "",
                isOwned: true,
                createdAt: Date(),
                photos: []
            )
        ]
        mockEncounterRepo.fetchAllResult = [
            CloudEncounter(
                recordName: "enc-hidden",
                ownerID: "private-user",
                catRecordName: "cat-hidden",
                date: Date(),
                locationName: "classified",
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "redacted",
                photos: []
            )
        ]

        let data = try await sut.fetchUserData(userID: "private-user")

        XCTAssertEqual(data.profile.displayName, "shiv")
        XCTAssertTrue(data.profile.isPrivate)
        XCTAssertTrue(data.cats.isEmpty, "cats should be empty for private profile when not following")
        XCTAssertTrue(data.encounters.isEmpty, "encounters should be empty for private profile when not following")
        XCTAssertTrue(mockCatRepo.fetchAllCalls.isEmpty, "should not fetch cats for private profile")
        XCTAssertTrue(mockEncounterRepo.fetchAllCalls.isEmpty, "should not fetch encounters for private profile")
    }

    func testPrivateProfileReturnsContentWhenFollowing() async throws {
        mockFollowService.simulateFollowing(followeeID: "private-user")
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-priv",
            appleUserID: "private-user",
            displayName: "shiv",
            bio: "you earned this",
            isPrivate: true
        )
        let cat = CloudCat(
            recordName: "cat-visible",
            ownerID: "private-user",
            name: "Ghost",
            breed: "",
            estimatedAge: "?",
            locationName: "home",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: true,
            createdAt: Date(),
            photos: []
        )
        mockCatRepo.fetchAllResult = [cat]
        mockEncounterRepo.fetchAllResult = []

        let data = try await sut.fetchUserData(userID: "private-user")

        XCTAssertEqual(data.cats.count, 1)
        XCTAssertEqual(data.cats.first?.name, "Ghost")
    }

    func testOwnPrivateProfileAlwaysReturnsContent() async throws {
        currentUserID = "my-user"
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-me",
            appleUserID: "my-user",
            displayName: "me",
            bio: "my profile",
            isPrivate: true
        )
        let cat = CloudCat(
            recordName: "cat-mine",
            ownerID: "my-user",
            name: "Steven",
            breed: "",
            estimatedAge: "5",
            locationName: "couch",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: true,
            createdAt: Date(),
            photos: []
        )
        mockCatRepo.fetchAllResult = [cat]
        mockEncounterRepo.fetchAllResult = []

        let data = try await sut.fetchUserData(userID: "my-user")

        XCTAssertEqual(data.cats.count, 1, "own private profile should always return content")
        XCTAssertEqual(data.cats.first?.name, "Steven")
    }

    func testPublicProfileAlwaysReturnsContent() async throws {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-pub",
            appleUserID: "public-user",
            displayName: "tuong",
            bio: "i see cats",
            isPrivate: false
        )
        let cat = CloudCat(
            recordName: "cat-pub",
            ownerID: "public-user",
            name: "Chairman Meow",
            breed: "",
            estimatedAge: "6",
            locationName: "fire escape",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: false,
            createdAt: Date(),
            photos: []
        )
        mockCatRepo.fetchAllResult = [cat]
        mockEncounterRepo.fetchAllResult = []

        let data = try await sut.fetchUserData(userID: "public-user")

        XCTAssertEqual(data.cats.count, 1)
        XCTAssertEqual(data.cats.first?.name, "Chairman Meow")
    }

    // MARK: - Caching

    func testCachedDataReturnsFetchedResult() async throws {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "cached user",
            bio: "",
            isPrivate: false
        )
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: "user-1")

        let cached = sut.cachedData(for: "user-1")
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.profile.displayName, "cached user")
    }

    func testCachedDataReturnsNilForUnknownUser() {
        XCTAssertNil(sut.cachedData(for: "unknown"))
    }

    func testSecondFetchUsesCacheWhenNotExpired() async throws {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "test",
            bio: "",
            isPrivate: false
        )
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: "user-1")
        _ = try await sut.fetchUserData(userID: "user-1")

        // CloudKit should only be called once — second fetch hits cache
        XCTAssertEqual(mockCloudKit.fetchedAppleUserIDs.count, 1)
    }

    func testClearCacheRemovesAllData() async throws {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "test",
            bio: "",
            isPrivate: false
        )
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: "user-1")
        sut.clearCache()

        XCTAssertNil(sut.cachedData(for: "user-1"))
    }

    // MARK: - fetchDisplayName

    func testFetchDisplayNameReturnsFromProfile() async {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "cool person",
            bio: "",
            isPrivate: false
        )

        let name = await sut.fetchDisplayName(userID: "user-1")
        XCTAssertEqual(name, "cool person")
    }

    func testFetchDisplayNameCachesResult() async {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "cool person",
            bio: "",
            isPrivate: false
        )

        _ = await sut.fetchDisplayName(userID: "user-1")
        _ = await sut.fetchDisplayName(userID: "user-1")

        // Only one CloudKit fetch — second call uses cache
        XCTAssertEqual(mockCloudKit.fetchedAppleUserIDs.count, 1)
    }

    func testFetchDisplayNameReturnsNilWhenNotFound() async {
        mockCloudKit.fetchResult = nil

        let name = await sut.fetchDisplayName(userID: "ghost")
        XCTAssertNil(name)
    }

    // MARK: - Loading state

    func testIsLoadingIsFalseByDefault() {
        XCTAssertFalse(sut.isLoading)
    }

    func testIsLoadingResetAfterFetch() async throws {
        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "test",
            bio: "",
            isPrivate: false
        )
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: "user-1")
        XCTAssertFalse(sut.isLoading)
    }

    func testIsLoadingResetAfterError() async {
        mockCloudKit.fetchResult = nil

        _ = try? await sut.fetchUserData(userID: "ghost")
        XCTAssertFalse(sut.isLoading)
    }
}
