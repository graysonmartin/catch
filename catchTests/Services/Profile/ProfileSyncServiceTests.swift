import XCTest
import SwiftData
import CatchCore

@MainActor
final class ProfileSyncServiceTests: XCTestCase {

    private var mockCloudKit: MockCloudKitService!
    private var sut: ProfileSyncService!
    private var container: ModelContainer!

    override func setUp() async throws {
        mockCloudKit = MockCloudKitService()
        sut = ProfileSyncService(cloudKitService: mockCloudKit)
        container = try ModelContainer.forTesting()
    }

    override func tearDown() async throws {
        mockCloudKit = nil
        sut = nil
        container = nil
    }

    // MARK: - syncProfile

    func testSyncProfileSavesToCloudKit() async throws {
        let context = container.mainContext
        let profile = UserProfile(
            displayName: "Test User",
            bio: "A bio",
            username: "testuser",
            appleUserID: "apple-123",
            isPrivate: false
        )
        context.insert(profile)

        mockCloudKit.saveResult = .success("ck-record-456")

        try await sut.syncProfile(profile)

        XCTAssertEqual(mockCloudKit.savedProfiles.count, 1)
        XCTAssertEqual(mockCloudKit.savedProfiles.first?.appleUserID, "apple-123")
        XCTAssertEqual(mockCloudKit.savedProfiles.first?.displayName, "Test User")
        XCTAssertEqual(mockCloudKit.savedProfiles.first?.bio, "A bio")
        XCTAssertEqual(mockCloudKit.savedProfiles.first?.username, "testuser")
        XCTAssertEqual(mockCloudKit.savedProfiles.first?.isPrivate, false)
        XCTAssertEqual(profile.cloudKitRecordName, "ck-record-456")
    }

    func testSyncProfileWithNilAppleUserIDDoesNothing() async throws {
        let context = container.mainContext
        let profile = UserProfile(displayName: "No Apple ID")
        context.insert(profile)

        try await sut.syncProfile(profile)

        XCTAssertTrue(mockCloudKit.savedProfiles.isEmpty)
        XCTAssertNil(profile.cloudKitRecordName)
    }

    func testSyncProfilePropagatesError() async throws {
        let context = container.mainContext
        let profile = UserProfile(
            displayName: "Error User",
            appleUserID: "apple-err"
        )
        context.insert(profile)

        mockCloudKit.saveResult = .failure(NSError(domain: "test", code: 1))

        do {
            try await sut.syncProfile(profile)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNil(profile.cloudKitRecordName)
        }
    }

    // MARK: - checkUsernameAvailability

    func testCheckUsernameAvailabilityPassesThrough() async throws {
        mockCloudKit.usernameAvailabilityResult = true
        let result = try await sut.checkUsernameAvailability("testuser")
        XCTAssertTrue(result)
        XCTAssertEqual(mockCloudKit.usernameAvailabilityCalls, ["testuser"])
    }

    func testCheckUsernameAvailabilityReturnsFalse() async throws {
        mockCloudKit.usernameAvailabilityResult = false
        let result = try await sut.checkUsernameAvailability("taken")
        XCTAssertFalse(result)
        XCTAssertEqual(mockCloudKit.usernameAvailabilityCalls, ["taken"])
    }
}
