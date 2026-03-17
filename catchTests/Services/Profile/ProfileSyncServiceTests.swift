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

    func testSyncProfileCreatesWhenNoExistingProfile() async throws {
        let profile = UserProfile(
            displayName: "Test User",
            bio: "A bio",
            username: "testuser",
            supabaseUserID: "supa-123",
            isPrivate: false
        )

        mockProfileRepo.fetchProfileResult = nil
        mockProfileRepo.createProfileResult = .fixture(
            id: UUID(),
            displayName: "Test User",
            username: "testuser",
            bio: "A bio"
        )

        try await sut.syncProfile(profile)

        XCTAssertEqual(mockProfileRepo.createProfileCalls.count, 1)
        XCTAssertEqual(mockProfileRepo.createProfileCalls.first?.id, "supa-123")
        XCTAssertEqual(mockProfileRepo.createProfileCalls.first?.payload.displayName, "Test User")
    }

    func testSyncProfileUpdatesWhenExistingProfile() async throws {
        let profile = UserProfile(
            displayName: "Updated User",
            bio: "New bio",
            username: "testuser",
            supabaseUserID: "supa-456",
            isPrivate: true
        )

        mockProfileRepo.fetchProfileResult = .fixture(id: UUID(), displayName: "Old Name")
        mockProfileRepo.updateProfileResult = .fixture(id: UUID(), displayName: "Updated User")

        try await sut.syncProfile(profile)

        XCTAssertEqual(mockProfileRepo.updateProfileCalls.count, 1)
        XCTAssertEqual(mockProfileRepo.updateProfileCalls.first?.id, "supa-456")
        XCTAssertTrue(mockProfileRepo.createProfileCalls.isEmpty)
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
    var checkUsernameCalls: [String] = []

    var fetchProfileResult: SupabaseProfile?
    var createProfileResult: SupabaseProfile?
    var updateProfileResult: SupabaseProfile?
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

    func searchUsers(query: String) async throws -> [SupabaseProfile] { [] }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        checkUsernameCalls.append(username)
        return usernameAvailabilityResult
    }
}

@MainActor
private final class MockSupabaseAssetService: SupabaseAssetService {
    func uploadPhoto(_ data: Data, bucket: SupabaseStorageBucket, ownerID: String, fileName: String) async throws -> String {
        "https://example.com/\(fileName)"
    }

    func uploadPhotos(_ photos: [Data], bucket: SupabaseStorageBucket, ownerID: String) async throws -> [String] {
        photos.indices.map { "https://example.com/photo_\($0).jpg" }
    }

    func deletePhoto(bucket: SupabaseStorageBucket, path: String) async throws {}

    func publicURL(bucket: SupabaseStorageBucket, path: String) -> String {
        "https://example.com/\(path)"
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
