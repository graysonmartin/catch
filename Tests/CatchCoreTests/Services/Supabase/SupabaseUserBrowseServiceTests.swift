import XCTest
@testable import CatchCore

@MainActor
final class SupabaseUserBrowseServiceTests: XCTestCase {

    private var sut: SupabaseUserBrowseService!
    private var mockProfileRepo: MockSupabaseProfileRepository!
    private var mockCatRepo: MockCatRepository!
    private var mockEncounterRepo: MockEncounterRepository!
    private var mockFollowService: MockFollowService!
    private var currentUserID: String?

    override func setUp() {
        super.setUp()
        mockProfileRepo = MockSupabaseProfileRepository()
        mockCatRepo = MockCatRepository()
        mockEncounterRepo = MockEncounterRepository()
        mockFollowService = MockFollowService()
        currentUserID = "current-user"
        sut = SupabaseUserBrowseService(
            profileRepository: mockProfileRepo,
            catRepository: mockCatRepo,
            encounterRepository: mockEncounterRepo,
            followService: mockFollowService,
            currentUserIDProvider: { [weak self] in self?.currentUserID }
        )
    }

    override func tearDown() {
        sut = nil
        mockProfileRepo = nil
        mockCatRepo = nil
        mockEncounterRepo = nil
        mockFollowService = nil
        currentUserID = nil
        super.tearDown()
    }

    // MARK: - fetchUserData

    func testFetchUserDataReturnsProfileAndData() async throws {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(
            id: userID, displayName: "cat lord", followerCount: 10, followingCount: 5
        )
        let cat = CloudCat(
            recordName: "cat-1", ownerID: userID.uuidString, name: "Muffin",
            breed: "", estimatedAge: "3", locationName: "park",
            locationLatitude: nil, locationLongitude: nil, notes: "",
            isOwned: false, createdAt: Date(), photos: []
        )
        mockCatRepo.fetchAllResult = [cat]
        let encounter = CloudEncounter(
            recordName: "enc-1", ownerID: userID.uuidString, catRecordName: "cat-1",
            date: Date(), locationName: "park", locationLatitude: nil, locationLongitude: nil,
            notes: "spotted", photos: []
        )
        mockEncounterRepo.fetchAllResult = [encounter]

        let data = try await sut.fetchUserData(userID: userID.uuidString)

        XCTAssertEqual(data.profile.displayName, "cat lord")
        XCTAssertEqual(data.cats.count, 1)
        XCTAssertEqual(data.cats.first?.name, "Muffin")
        XCTAssertEqual(data.encounters.count, 1)
        XCTAssertEqual(data.encounters.first?.notes, "spotted")
        XCTAssertEqual(data.followerCount, 10)
        XCTAssertEqual(data.followingCount, 5)
        XCTAssertFalse(data.isExpired)
    }

    func testFetchUserDataThrowsUserNotFoundWhenNoProfile() async {
        mockProfileRepo.fetchProfileResult = nil

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
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID)
        mockCatRepo.fetchAllError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])

        do {
            _ = try await sut.fetchUserData(userID: userID.uuidString)
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
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(
            id: userID, displayName: "shiv", isPrivate: true, followerCount: 7, followingCount: 3
        )
        mockCatRepo.fetchAllResult = [
            CloudCat(
                recordName: "cat-hidden", ownerID: userID.uuidString, name: "Ghost",
                breed: "", estimatedAge: "?", locationName: "classified",
                locationLatitude: nil, locationLongitude: nil, notes: "",
                isOwned: true, createdAt: Date(), photos: []
            )
        ]

        let data = try await sut.fetchUserData(userID: userID.uuidString)

        XCTAssertEqual(data.profile.displayName, "shiv")
        XCTAssertTrue(data.profile.isPrivate)
        XCTAssertTrue(data.cats.isEmpty, "cats should be empty for private profile when not following")
        XCTAssertTrue(data.encounters.isEmpty, "encounters should be empty for private profile when not following")
        XCTAssertTrue(mockCatRepo.fetchAllCalls.isEmpty, "should not fetch cats for private profile")
        XCTAssertTrue(mockEncounterRepo.fetchAllCalls.isEmpty, "should not fetch encounters for private profile")
        XCTAssertEqual(data.followerCount, 7)
        XCTAssertEqual(data.followingCount, 3)
    }

    func testPrivateProfileReturnsContentWhenFollowing() async throws {
        let userID = UUID()
        mockFollowService.simulateFollowing(followeeID: userID.uuidString)
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "shiv", isPrivate: true)
        let cat = CloudCat(
            recordName: "cat-visible", ownerID: userID.uuidString, name: "Ghost",
            breed: "", estimatedAge: "?", locationName: "home",
            locationLatitude: nil, locationLongitude: nil, notes: "",
            isOwned: true, createdAt: Date(), photos: []
        )
        mockCatRepo.fetchAllResult = [cat]
        mockEncounterRepo.fetchAllResult = []

        let data = try await sut.fetchUserData(userID: userID.uuidString)

        XCTAssertEqual(data.cats.count, 1)
        XCTAssertEqual(data.cats.first?.name, "Ghost")
    }

    func testOwnPrivateProfileAlwaysReturnsContent() async throws {
        let userID = UUID()
        currentUserID = userID.uuidString
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "me", isPrivate: true)
        let cat = CloudCat(
            recordName: "cat-mine", ownerID: userID.uuidString, name: "Steven",
            breed: "", estimatedAge: "5", locationName: "couch",
            locationLatitude: nil, locationLongitude: nil, notes: "",
            isOwned: true, createdAt: Date(), photos: []
        )
        mockCatRepo.fetchAllResult = [cat]
        mockEncounterRepo.fetchAllResult = []

        let data = try await sut.fetchUserData(userID: userID.uuidString)

        XCTAssertEqual(data.cats.count, 1, "own private profile should always return content")
        XCTAssertEqual(data.cats.first?.name, "Steven")
    }

    func testPublicProfileAlwaysReturnsContent() async throws {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "tuong")
        let cat = CloudCat(
            recordName: "cat-pub", ownerID: userID.uuidString, name: "Chairman Meow",
            breed: "", estimatedAge: "6", locationName: "fire escape",
            locationLatitude: nil, locationLongitude: nil, notes: "",
            isOwned: false, createdAt: Date(), photos: []
        )
        mockCatRepo.fetchAllResult = [cat]
        mockEncounterRepo.fetchAllResult = []

        let data = try await sut.fetchUserData(userID: userID.uuidString)

        XCTAssertEqual(data.cats.count, 1)
        XCTAssertEqual(data.cats.first?.name, "Chairman Meow")
    }

    // MARK: - Caching

    func testCachedDataReturnsFetchedResult() async throws {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "cached user")
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: userID.uuidString)

        let cached = sut.cachedData(for: userID.uuidString)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.profile.displayName, "cached user")
    }

    func testCachedDataReturnsNilForUnknownUser() {
        XCTAssertNil(sut.cachedData(for: "unknown"))
    }

    func testSecondFetchUsesCacheWhenNotExpired() async throws {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "test")
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: userID.uuidString)
        _ = try await sut.fetchUserData(userID: userID.uuidString)

        XCTAssertEqual(mockProfileRepo.fetchProfileCalls.count, 1)
    }

    func testClearCacheRemovesAllData() async throws {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "test")
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: userID.uuidString)
        sut.clearCache()

        XCTAssertNil(sut.cachedData(for: userID.uuidString))
    }

    // MARK: - fetchDisplayName

    func testFetchDisplayNameReturnsFromProfile() async {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "cool person")

        let name = await sut.fetchDisplayName(userID: userID.uuidString)
        XCTAssertEqual(name, "cool person")
    }

    func testFetchDisplayNameCachesResult() async {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "cool person")

        _ = await sut.fetchDisplayName(userID: userID.uuidString)
        _ = await sut.fetchDisplayName(userID: userID.uuidString)

        XCTAssertEqual(mockProfileRepo.fetchProfileCalls.count, 1)
    }

    func testFetchDisplayNameReturnsNilWhenNotFound() async {
        mockProfileRepo.fetchProfileResult = nil

        let name = await sut.fetchDisplayName(userID: "ghost")
        XCTAssertNil(name)
    }

    // MARK: - fetchProfile

    func testFetchProfileReturnsFromRepository() async {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "fetched")

        let profile = await sut.fetchProfile(userID: userID.uuidString)

        XCTAssertEqual(profile?.displayName, "fetched")
        XCTAssertEqual(profile?.recordName, userID.uuidString)
    }

    func testFetchProfileReturnsNilWhenNotFound() async {
        mockProfileRepo.fetchProfileResult = nil

        let profile = await sut.fetchProfile(userID: "ghost")
        XCTAssertNil(profile)
    }

    func testFetchProfileReturnsCachedResult() async throws {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID, displayName: "cached")
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: userID.uuidString)
        mockProfileRepo.fetchProfileCalls.removeAll()

        let profile = await sut.fetchProfile(userID: userID.uuidString)

        XCTAssertEqual(profile?.displayName, "cached")
        XCTAssertTrue(mockProfileRepo.fetchProfileCalls.isEmpty, "should use cache, not fetch again")
    }

    // MARK: - Loading state

    func testIsLoadingIsFalseByDefault() {
        XCTAssertFalse(sut.isLoading)
    }

    func testIsLoadingResetAfterFetch() async throws {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(id: userID)
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        _ = try await sut.fetchUserData(userID: userID.uuidString)
        XCTAssertFalse(sut.isLoading)
    }

    func testIsLoadingResetAfterError() async {
        mockProfileRepo.fetchProfileResult = nil

        _ = try? await sut.fetchUserData(userID: "ghost")
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Follower counts from profile

    func testFollowerCountsReadFromProfileNotFollowService() async throws {
        let userID = UUID()
        mockProfileRepo.fetchProfileResult = makeSupabaseProfile(
            id: userID, followerCount: 99, followingCount: 42
        )
        mockCatRepo.fetchAllResult = []
        mockEncounterRepo.fetchAllResult = []

        let data = try await sut.fetchUserData(userID: userID.uuidString)

        XCTAssertEqual(data.followerCount, 99)
        XCTAssertEqual(data.followingCount, 42)
        XCTAssertTrue(mockFollowService.fetchFollowCountsCalls.isEmpty, "should not call followService for counts")
    }

    // MARK: - Helpers

    private func makeSupabaseProfile(
        id: UUID = UUID(),
        displayName: String = "test",
        username: String = "test_user",
        bio: String = "",
        isPrivate: Bool = false,
        followerCount: Int = 0,
        followingCount: Int = 0
    ) -> SupabaseProfile {
        SupabaseProfile(
            id: id,
            displayName: displayName,
            username: username,
            bio: bio,
            isPrivate: isPrivate,
            showCats: true,
            showEncounters: true,
            avatarUrl: nil,
            followerCount: followerCount,
            followingCount: followingCount,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
