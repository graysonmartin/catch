import XCTest
import CatchCore

@MainActor
final class ProfileSyncServiceTests: XCTestCase {

    private var mockProfileRepo: MockSupabaseProfileRepo!
    private var mockAssetService: MockSupabaseAssetService!
    private var sut: ProfileSyncService!

    override func setUp() async throws {
        mockProfileRepo = MockSupabaseProfileRepo()
        mockAssetService = MockSupabaseAssetService()
        sut = ProfileSyncService(
            profileRepository: mockProfileRepo,
            assetService: mockAssetService
        )
    }

    override func tearDown() async throws {
        mockProfileRepo = nil
        mockAssetService = nil
        sut = nil
    }

    // MARK: - syncProfile

    func testSyncProfileUsesUpsert() async throws {
        let profile = UserProfile(
            displayName: "Test User",
            bio: "A bio",
            username: "testuser",
            supabaseUserID: "supa-123",
            isPrivate: false
        )

        try await sut.syncProfile(profile)

        XCTAssertEqual(mockProfileRepo.upsertProfileCalls.count, 1)
        XCTAssertEqual(mockProfileRepo.upsertProfileCalls.first?.id, "supa-123")
        XCTAssertEqual(mockProfileRepo.upsertProfileCalls.first?.payload.displayName, "Test User")
        // Verify no separate fetch + create/update calls
        XCTAssertTrue(mockProfileRepo.fetchProfileCalls.isEmpty)
        XCTAssertTrue(mockProfileRepo.createProfileCalls.isEmpty)
        XCTAssertTrue(mockProfileRepo.updateProfileCalls.isEmpty)
    }

    func testSyncProfileUpsertSendsCorrectPayload() async throws {
        let profile = UserProfile(
            displayName: "Updated User",
            bio: "New bio",
            username: "testuser",
            supabaseUserID: "supa-456",
            isPrivate: true
        )

        try await sut.syncProfile(profile)

        XCTAssertEqual(mockProfileRepo.upsertProfileCalls.count, 1)
        XCTAssertEqual(mockProfileRepo.upsertProfileCalls.first?.id, "supa-456")
        XCTAssertEqual(mockProfileRepo.upsertProfileCalls.first?.payload.isPrivate, true)
        XCTAssertEqual(mockProfileRepo.upsertProfileCalls.first?.payload.bio, "New bio")
    }

    func testSyncProfileWithRemovedAvatarDeletesFromStorage() async throws {
        let profile = UserProfile(
            displayName: "Test",
            bio: "",
            username: "testuser",
            supabaseUserID: "supa-789",
            isPrivate: false,
            avatarUrl: "https://example.com/old-avatar.jpg"
        )

        let result = try await sut.syncProfile(profile, avatarChange: .removed)

        XCTAssertNil(result)
        XCTAssertEqual(mockAssetService.deletePhotoCalls.count, 1)
        XCTAssertEqual(mockAssetService.deletePhotoCalls.first?.bucket, .profilePhotos)
        XCTAssertEqual(mockAssetService.deletePhotoCalls.first?.path, "supa-789/old-avatar.jpg")
        XCTAssertNil(mockProfileRepo.upsertProfileCalls.first?.payload.avatarUrl)
    }

    func testSyncProfileWithNilSupabaseUserIDDoesNothing() async throws {
        let profile = UserProfile(displayName: "No ID")

        try await sut.syncProfile(profile)

        XCTAssertTrue(mockProfileRepo.fetchProfileCalls.isEmpty)
        XCTAssertTrue(mockProfileRepo.createProfileCalls.isEmpty)
    }

    // MARK: - checkUsernameAvailability

    func testCheckUsernameAvailabilityPassesThrough() async throws {
        mockProfileRepo.usernameAvailabilityResult = true
        let result = try await sut.checkUsernameAvailability("testuser")
        XCTAssertTrue(result)
        XCTAssertEqual(mockProfileRepo.checkUsernameCalls, ["testuser"])
    }

    func testCheckUsernameAvailabilityReturnsFalse() async throws {
        mockProfileRepo.usernameAvailabilityResult = false
        let result = try await sut.checkUsernameAvailability("taken")
        XCTAssertFalse(result)
    }
}

// MARK: - Mock (app-level)

@MainActor
private final class MockSupabaseProfileRepo: SupabaseProfileRepository {
    var fetchProfileCalls: [String] = []
    var createProfileCalls: [(payload: SupabaseProfilePayload, id: String)] = []
    var updateProfileCalls: [(id: String, payload: SupabaseProfilePayload)] = []
    var upsertProfileCalls: [(payload: SupabaseProfilePayload, id: String)] = []
    var checkUsernameCalls: [String] = []

    var fetchProfileResult: SupabaseProfile?
    var createProfileResult: SupabaseProfile?
    var updateProfileResult: SupabaseProfile?
    var upsertProfileResult: SupabaseProfile?
    var usernameAvailabilityResult: Bool = true

    func fetchProfile(id: String) async throws -> SupabaseProfile? {
        fetchProfileCalls.append(id)
        return fetchProfileResult
    }

    func fetchProfiles(ids: [String]) async throws -> [SupabaseProfile] { [] }

    func createProfile(_ payload: SupabaseProfilePayload, id: String) async throws -> SupabaseProfile {
        createProfileCalls.append((payload, id))
        return createProfileResult ?? .fixture()
    }

    func updateProfile(id: String, _ payload: SupabaseProfilePayload) async throws -> SupabaseProfile {
        updateProfileCalls.append((id, payload))
        return updateProfileResult ?? .fixture()
    }

    func upsertProfile(_ payload: SupabaseProfilePayload, id: String) async throws -> SupabaseProfile {
        upsertProfileCalls.append((payload, id))
        return upsertProfileResult ?? .fixture()
    }

    func searchUsers(query: String) async throws -> [SupabaseProfile] { [] }

    func fetchRecentPublicUsers(excluding excludedIDs: Set<String>, limit: Int) async throws -> [SupabaseProfile] { [] }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        checkUsernameCalls.append(username)
        return usernameAvailabilityResult
    }
}

extension SupabaseProfile {
    fileprivate static func fixture(
        id: UUID = UUID(),
        displayName: String = "test",
        username: String = "test_user",
        bio: String = ""
    ) -> SupabaseProfile {
        SupabaseProfile(
            id: id,
            displayName: displayName,
            username: username,
            bio: bio,
            isPrivate: false,
            showCats: true,
            showEncounters: true,
            avatarUrl: nil,
            followerCount: 0,
            followingCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
