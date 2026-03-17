import XCTest
@testable import CatchCore

final class SupabaseProfileMapperTests: XCTestCase {

    func testMapsIDToRecordNameAndAppleUserID() {
        let id = UUID()
        let profile = SupabaseProfile.fixture(id: id)

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertEqual(result.recordName, id.uuidString.lowercased())
        XCTAssertEqual(result.appleUserID, id.uuidString.lowercased())
    }

    func testMapsDisplayNameAndBio() {
        let profile = SupabaseProfile.fixture(displayName: "cat lord", bio: "i pet cats")

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertEqual(result.displayName, "cat lord")
        XCTAssertEqual(result.bio, "i pet cats")
    }

    func testMapsUsername() {
        let profile = SupabaseProfile.fixture(username: "catlord42")

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertEqual(result.username, "catlord42")
    }

    func testMapsPrivateFlag() {
        let publicProfile = SupabaseProfile.fixture(isPrivate: false)
        let privateProfile = SupabaseProfile.fixture(isPrivate: true)

        XCTAssertFalse(SupabaseProfileMapper.toCloudUserProfile(publicProfile).isPrivate)
        XCTAssertTrue(SupabaseProfileMapper.toCloudUserProfile(privateProfile).isPrivate)
    }

    func testAvatarDataIsAlwaysNil() {
        let profile = SupabaseProfile.fixture(avatarUrl: "https://example.com/avatar.jpg")

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertNil(result.avatarData)
    }

    func testMapsAvatarURL() {
        let profile = SupabaseProfile.fixture(avatarUrl: "https://example.com/avatar.jpg")

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertEqual(result.avatarURL, "https://example.com/avatar.jpg")
    }

    func testMapsNilAvatarURL() {
        let profile = SupabaseProfile.fixture(avatarUrl: nil)

        let result = SupabaseProfileMapper.toCloudUserProfile(profile)

        XCTAssertNil(result.avatarURL)
    }

}
