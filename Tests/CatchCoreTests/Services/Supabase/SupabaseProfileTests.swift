import XCTest
@testable import CatchCore

final class SupabaseProfileTests: XCTestCase {

    // MARK: - Decoding

    func testDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "display_name": "cat lord",
            "username": "catlord42",
            "bio": "i pet cats",
            "is_private": false,
            "show_cats": true,
            "show_encounters": true,
            "avatar_url": "https://example.com/avatar.jpg",
            "follower_count": 42,
            "following_count": 15,
            "created_at": "2025-01-15T10:30:00Z",
            "updated_at": "2025-06-01T14:00:00Z"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = try decoder.decode(SupabaseProfile.self, from: data)

        XCTAssertEqual(profile.id, UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000"))
        XCTAssertEqual(profile.displayName, "cat lord")
        XCTAssertEqual(profile.username, "catlord42")
        XCTAssertEqual(profile.bio, "i pet cats")
        XCTAssertFalse(profile.isPrivate)
        XCTAssertTrue(profile.showCats)
        XCTAssertTrue(profile.showEncounters)
        XCTAssertEqual(profile.avatarUrl, "https://example.com/avatar.jpg")
        XCTAssertEqual(profile.followerCount, 42)
        XCTAssertEqual(profile.followingCount, 15)
    }

    func testDecodesWithNullAvatarUrl() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "display_name": "no avatar",
            "username": "noavatar",
            "bio": "",
            "is_private": true,
            "show_cats": false,
            "show_encounters": false,
            "avatar_url": null,
            "follower_count": 0,
            "following_count": 0,
            "created_at": "2025-01-15T10:30:00Z",
            "updated_at": "2025-01-15T10:30:00Z"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = try decoder.decode(SupabaseProfile.self, from: data)

        XCTAssertNil(profile.avatarUrl)
        XCTAssertTrue(profile.isPrivate)
        XCTAssertFalse(profile.showCats)
        XCTAssertFalse(profile.showEncounters)
    }

    // MARK: - Encoding

    func testEncodesToSnakeCaseJSON() throws {
        let profile = SupabaseProfile(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            displayName: "test user",
            username: "testuser",
            bio: "testing",
            isPrivate: false,
            showCats: true,
            showEncounters: true,
            avatarUrl: "https://example.com/avatar.jpg",
            followerCount: 10,
            followingCount: 5,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(dict?["display_name"])
        XCTAssertNotNil(dict?["is_private"])
        XCTAssertNotNil(dict?["show_cats"])
        XCTAssertNotNil(dict?["show_encounters"])
        XCTAssertNotNil(dict?["avatar_url"])
        XCTAssertNotNil(dict?["follower_count"])
        XCTAssertNotNil(dict?["following_count"])
        XCTAssertNotNil(dict?["created_at"])
        XCTAssertNotNil(dict?["updated_at"])
    }

    func testRoundTrip() throws {
        let original = SupabaseProfile(
            id: UUID(),
            displayName: "round trip",
            username: "roundtrip",
            bio: "going nowhere",
            isPrivate: true,
            showCats: false,
            showEncounters: true,
            avatarUrl: "https://example.com/pic.png",
            followerCount: 100,
            followingCount: 50,
            createdAt: Date(timeIntervalSinceReferenceDate: 700000000),
            updatedAt: Date(timeIntervalSinceReferenceDate: 700000000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SupabaseProfile.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.displayName, original.displayName)
        XCTAssertEqual(decoded.username, original.username)
        XCTAssertEqual(decoded.bio, original.bio)
        XCTAssertEqual(decoded.isPrivate, original.isPrivate)
        XCTAssertEqual(decoded.showCats, original.showCats)
        XCTAssertEqual(decoded.showEncounters, original.showEncounters)
        XCTAssertEqual(decoded.avatarUrl, original.avatarUrl)
        XCTAssertEqual(decoded.followerCount, original.followerCount)
        XCTAssertEqual(decoded.followingCount, original.followingCount)
    }
}
