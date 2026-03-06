import XCTest
@testable import CatchCore

@MainActor
final class CloudUserProfileAvatarTests: XCTestCase {

    // MARK: - CloudUserProfile Model

    func test_initWithAvatarData_storesAvatar() {
        let avatar = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let profile = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "Test",
            bio: "bio",
            isPrivate: false,
            avatarData: avatar
        )

        XCTAssertEqual(profile.avatarData, avatar)
    }

    func test_initWithoutAvatarData_defaultsToNil() {
        let profile = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "Test",
            bio: "bio",
            isPrivate: false
        )

        XCTAssertNil(profile.avatarData)
    }

    func test_initWithNilAvatarData_storesNil() {
        let profile = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "Test",
            bio: "bio",
            isPrivate: false,
            avatarData: nil
        )

        XCTAssertNil(profile.avatarData)
    }

    // MARK: - Mock Service Avatar Passthrough

    func test_saveUserProfile_tracksAvatarData() async throws {
        let mock = MockCloudKitService()
        let avatar = Data([0x89, 0x50, 0x4E, 0x47])

        _ = try await mock.saveUserProfile(
            appleUserID: "user-1",
            displayName: "Test",
            bio: "bio",
            username: "test_user",
            isPrivate: false,
            avatarData: avatar
        )

        XCTAssertEqual(mock.savedProfiles.count, 1)
        XCTAssertEqual(mock.savedProfiles.first?.avatarData, avatar)
    }

    func test_saveUserProfile_tracksNilAvatarData() async throws {
        let mock = MockCloudKitService()

        _ = try await mock.saveUserProfile(
            appleUserID: "user-1",
            displayName: "Test",
            bio: "bio",
            username: nil,
            isPrivate: false,
            avatarData: nil
        )

        XCTAssertEqual(mock.savedProfiles.count, 1)
        XCTAssertNil(mock.savedProfiles.first?.avatarData)
    }

    func test_fetchUserProfile_returnsAvatarData() async throws {
        let mock = MockCloudKitService()
        let avatar = Data([0xFF, 0xD8, 0xFF, 0xE0])
        mock.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "Test",
            bio: "bio",
            isPrivate: false,
            avatarData: avatar
        )

        let result = try await mock.fetchUserProfile(appleUserID: "user-1")

        XCTAssertEqual(result?.avatarData, avatar)
    }

    func test_fetchUserProfile_returnsNilAvatarWhenNotSet() async throws {
        let mock = MockCloudKitService()
        mock.fetchResult = CloudUserProfile(
            recordName: "rec-1",
            appleUserID: "user-1",
            displayName: "Test",
            bio: "bio",
            isPrivate: false
        )

        let result = try await mock.fetchUserProfile(appleUserID: "user-1")

        XCTAssertNil(result?.avatarData)
    }

    func test_searchUsers_returnsAvatarData() async throws {
        let mock = MockCloudKitService()
        let avatar = Data([0x89, 0x50, 0x4E, 0x47])
        mock.searchUsersResult = [
            CloudUserProfile(
                recordName: "rec-1",
                appleUserID: "user-1",
                displayName: "Cat Lover",
                bio: "meow",
                isPrivate: false,
                avatarData: avatar
            )
        ]

        let results = try await mock.searchUsers(query: "Cat")

        XCTAssertEqual(results.first?.avatarData, avatar)
    }
}
