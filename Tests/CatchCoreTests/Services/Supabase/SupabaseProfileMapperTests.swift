import XCTest
@testable import CatchCore

final class SupabaseProfileMapperTests: XCTestCase {

    func testMapsIDToRecordNameAndAppleUserID() {
        let id = UUID()
        let profile = makeProfile(id: id)

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertEqual(result.recordName, id.uuidString)
        XCTAssertEqual(result.appleUserID, id.uuidString)
    }

    func testMapsDisplayNameAndBio() {
        let profile = makeProfile(displayName: "cat lord", bio: "i pet cats")

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertEqual(result.displayName, "cat lord")
        XCTAssertEqual(result.bio, "i pet cats")
    }

    func testMapsUsername() {
        let profile = makeProfile(username: "catlord42")

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertEqual(result.username, "catlord42")
    }

    func testMapsPrivateFlag() {
        let publicProfile = makeProfile(isPrivate: false)
        let privateProfile = makeProfile(isPrivate: true)

        XCTAssertFalse(SupabaseProfileMapper.toCloudUserProfile(publicProfile).isPrivate)
        XCTAssertTrue(SupabaseProfileMapper.toCloudUserProfile(privateProfile).isPrivate)
    }

    func testAvatarDataIsAlwaysNil() {
        let profile = makeProfile(avatarUrl: "https://example.com/avatar.jpg")

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertNil(result.avatarData)
    }

    func testMapsAvatarURL() {
        let profile = makeProfile(avatarUrl: "https://example.com/avatar.jpg")

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertEqual(result.avatarURL, "https://example.com/avatar.jpg")
    }

    func testMapsNilAvatarURL() {
        let profile = makeProfile(avatarUrl: nil)

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertNil(result.avatarURL)
    }

    // MARK: - Helpers

    private func makeProfile(
        id: UUID = UUID(),
        displayName: String = "test",
        username: String = "test_user",
        bio: String = "",
        isPrivate: Bool = false,
        avatarUrl: String? = nil
    ) -> SupabaseProfile {
        SupabaseProfile(
            id: id,
            displayName: displayName,
            username: username,
            bio: bio,
            isPrivate: isPrivate,
            showCats: true,
            showEncounters: true,
            avatarUrl: avatarUrl,
            followerCount: 0,
            followingCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
