import XCTest
@testable import CatchCore

@MainActor
final class SuggestedPeopleServiceTests: XCTestCase {

    private var profileRepo: MockSupabaseProfileRepository!
    private var catRepo: MockCatRepository!
    private var currentUserID: String!
    private var followedIDs: Set<String>!
    private var sut: SuggestedPeopleService!

    override func setUp() {
        super.setUp()
        profileRepo = MockSupabaseProfileRepository()
        catRepo = MockCatRepository()
        currentUserID = "current-user"
        followedIDs = []

        sut = SuggestedPeopleService(
            profileRepository: profileRepo,
            catRepository: catRepo,
            currentUserIDProvider: { [unowned self] in self.currentUserID },
            followedIDsProvider: { [unowned self] in self.followedIDs }
        )
    }

    override func tearDown() {
        sut = nil
        profileRepo = nil
        catRepo = nil
        super.tearDown()
    }

    // MARK: - Loading

    func test_loadIfNeeded_fetchesOnFirstCall() async {
        let profile = SupabaseProfile.fixture(displayName: "Cat Person", username: "catperson")
        profileRepo.fetchRecentPublicUsersResult = [profile]

        await sut.loadIfNeeded()

        XCTAssertTrue(sut.hasLoaded)
        XCTAssertEqual(sut.suggestedPeople.count, 1)
        XCTAssertEqual(sut.suggestedPeople.first?.displayName, "Cat Person")
    }

    func test_loadIfNeeded_doesNotRefetchIfAlreadyLoaded() async {
        profileRepo.fetchRecentPublicUsersResult = [
            SupabaseProfile.fixture(displayName: "User1")
        ]

        await sut.loadIfNeeded()
        XCTAssertEqual(profileRepo.fetchRecentPublicUsersCalls.count, 1)

        await sut.loadIfNeeded()
        XCTAssertEqual(profileRepo.fetchRecentPublicUsersCalls.count, 1)
    }

    func test_load_alwaysRefetches() async {
        profileRepo.fetchRecentPublicUsersResult = [
            SupabaseProfile.fixture(displayName: "User1")
        ]

        await sut.load()
        await sut.load()

        XCTAssertEqual(profileRepo.fetchRecentPublicUsersCalls.count, 2)
    }

    // MARK: - Filtering

    func test_excludesCurrentUser() async {
        let profile = SupabaseProfile.fixture(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "Other"
        )
        profileRepo.fetchRecentPublicUsersResult = [profile]

        // The current user ID does not match the profile, so it should appear
        currentUserID = "different-user"

        await sut.load()

        XCTAssertEqual(sut.suggestedPeople.count, 1)

        // Verify the excluded IDs passed to the repository contain the current user
        let lastCall = profileRepo.fetchRecentPublicUsersCalls.last
        XCTAssertTrue(lastCall?.excludedIDs.contains("different-user") ?? false)
    }

    func test_excludesFollowedUsers() async {
        followedIDs = ["followed-user-1", "followed-user-2"]

        let profile = SupabaseProfile.fixture(displayName: "Stranger")
        profileRepo.fetchRecentPublicUsersResult = [profile]

        await sut.load()

        let lastCall = profileRepo.fetchRecentPublicUsersCalls.last
        XCTAssertTrue(lastCall?.excludedIDs.contains("followed-user-1") ?? false)
        XCTAssertTrue(lastCall?.excludedIDs.contains("followed-user-2") ?? false)
    }

    // MARK: - Cat Counts

    func test_fetchesCatCountsViaBatchQuery() async {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000042")!
        let profile = SupabaseProfile.fixture(id: userID, displayName: "Cat Collector")
        profileRepo.fetchRecentPublicUsersResult = [profile]

        catRepo.fetchCatCountsResult = [userID.uuidString.lowercased(): 3]

        await sut.load()

        XCTAssertEqual(sut.suggestedPeople.first?.catCount, 3)
        // Verify the batch method was called with the correct user IDs
        XCTAssertEqual(catRepo.fetchCatCountsCalls.count, 1)
        XCTAssertEqual(catRepo.fetchCatCountsCalls.first, [userID.uuidString.lowercased()])
        // Verify the old N+1 fetchAll was NOT called
        XCTAssertTrue(catRepo.fetchAllCalls.isEmpty)
    }

    func test_batchCatCountsForMultipleUsers() async {
        let user1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let user2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        profileRepo.fetchRecentPublicUsersResult = [
            SupabaseProfile.fixture(id: user1ID, displayName: "User1"),
            SupabaseProfile.fixture(id: user2ID, displayName: "User2")
        ]

        catRepo.fetchCatCountsResult = [
            user1ID.uuidString.lowercased(): 5,
            user2ID.uuidString.lowercased(): 2
        ]

        await sut.load()

        XCTAssertEqual(sut.suggestedPeople.count, 2)
        XCTAssertEqual(sut.suggestedPeople.first(where: { $0.displayName == "User1" })?.catCount, 5)
        XCTAssertEqual(sut.suggestedPeople.first(where: { $0.displayName == "User2" })?.catCount, 2)
        // Single batch call, not N individual calls
        XCTAssertEqual(catRepo.fetchCatCountsCalls.count, 1)
    }

    // MARK: - Username Handling

    func test_emptyUsernameMappedasNil() async {
        let profile = SupabaseProfile.fixture(displayName: "NoUser", username: "")
        profileRepo.fetchRecentPublicUsersResult = [profile]

        await sut.load()

        XCTAssertNil(sut.suggestedPeople.first?.username)
    }

    func test_nonEmptyUsernamePreserved() async {
        let profile = SupabaseProfile.fixture(displayName: "HasUser", username: "catfan99")
        profileRepo.fetchRecentPublicUsersResult = [profile]

        await sut.load()

        XCTAssertEqual(sut.suggestedPeople.first?.username, "catfan99")
    }

    // MARK: - Error Handling

    func test_repositoryError_resultsInEmptySuggestions() async {
        profileRepo.fetchProfileError = NSError(domain: "test", code: 1)

        await sut.load()

        XCTAssertTrue(sut.suggestedPeople.isEmpty)
        XCTAssertTrue(sut.hasLoaded)
    }

    // MARK: - Remove Suggestion

    func test_removeSuggestion_removesMatchingPerson() async {
        let user1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let user2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        profileRepo.fetchRecentPublicUsersResult = [
            SupabaseProfile.fixture(id: user1ID, displayName: "User1"),
            SupabaseProfile.fixture(id: user2ID, displayName: "User2")
        ]

        await sut.load()
        XCTAssertEqual(sut.suggestedPeople.count, 2)

        sut.removeSuggestion(id: user1ID.uuidString.lowercased())
        XCTAssertEqual(sut.suggestedPeople.count, 1)
        XCTAssertEqual(sut.suggestedPeople.first?.displayName, "User2")
    }

    // MARK: - Privacy

    func test_privateFlag_passedThrough() async {
        let profile = SupabaseProfile.fixture(
            displayName: "Private User",
            isPrivate: true
        )
        profileRepo.fetchRecentPublicUsersResult = [profile]

        await sut.load()

        // Note: the repository query filters is_private = false server-side,
        // but the model passes through whatever the repo returns.
        // This test verifies the isPrivate field is correctly mapped.
        XCTAssertTrue(sut.suggestedPeople.first?.isPrivate ?? false)
    }
}
