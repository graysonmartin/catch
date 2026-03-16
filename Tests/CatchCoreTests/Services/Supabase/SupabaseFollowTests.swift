import XCTest
@testable import CatchCore

final class SupabaseFollowTests: XCTestCase {

    // MARK: - Decoding

    func testDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "follower_id": "660e8400-e29b-41d4-a716-446655440001",
            "followee_id": "770e8400-e29b-41d4-a716-446655440002",
            "status": "active",
            "created_at": "2025-06-15T10:30:00+00:00"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let follow = try decoder.decode(SupabaseFollow.self, from: json)

        XCTAssertEqual(follow.id.uuidString.lowercased(), "550e8400-e29b-41d4-a716-446655440000")
        XCTAssertEqual(follow.followerID.uuidString.lowercased(), "660e8400-e29b-41d4-a716-446655440001")
        XCTAssertEqual(follow.followeeID.uuidString.lowercased(), "770e8400-e29b-41d4-a716-446655440002")
        XCTAssertEqual(follow.status, "active")
    }

    func testDecodesPendingStatus() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "follower_id": "660e8400-e29b-41d4-a716-446655440001",
            "followee_id": "770e8400-e29b-41d4-a716-446655440002",
            "status": "pending",
            "created_at": "2025-06-15T10:30:00+00:00"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let follow = try decoder.decode(SupabaseFollow.self, from: json)
        XCTAssertEqual(follow.status, "pending")
    }

    // MARK: - Encoding

    func testInsertPayloadEncodesToSnakeCase() throws {
        let payload = SupabaseFollowInsertPayload(
            followerID: "user-1",
            followeeID: "user-2",
            status: "active"
        )

        let data = try JSONEncoder().encode(payload)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["follower_id"] as? String, "user-1")
        XCTAssertEqual(dict["followee_id"] as? String, "user-2")
        XCTAssertEqual(dict["status"] as? String, "active")
        XCTAssertNil(dict["followerID"])
    }

    func testUpdatePayloadEncodesStatus() throws {
        let payload = SupabaseFollowUpdatePayload(status: "active")

        let data = try JSONEncoder().encode(payload)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["status"] as? String, "active")
    }

    // MARK: - Domain Mapping

    func testToDomainMapsActiveFollow() {
        let id = UUID()
        let followerID = UUID()
        let followeeID = UUID()
        let date = Date()

        let supabaseFollow = SupabaseFollow(
            id: id,
            followerID: followerID,
            followeeID: followeeID,
            status: "active",
            createdAt: date
        )

        let follow = supabaseFollow.toDomain()

        XCTAssertEqual(follow.id, id.uuidString)
        XCTAssertEqual(follow.followerID, followerID.uuidString)
        XCTAssertEqual(follow.followeeID, followeeID.uuidString)
        XCTAssertEqual(follow.status, .active)
        XCTAssertTrue(follow.isActive)
        XCTAssertEqual(follow.createdAt, date)
    }

    func testToDomainMapsPendingFollow() {
        let follow = SupabaseFollow.fixture(status: "pending").toDomain()

        XCTAssertEqual(follow.status, .pending)
        XCTAssertTrue(follow.isPending)
    }

    func testToDomainDefaultsToPendingForUnknownStatus() {
        let follow = SupabaseFollow.fixture(status: "unknown").toDomain()

        XCTAssertEqual(follow.status, .pending)
    }

    // MARK: - Roundtrip

    func testEncodeDecodeRoundtrip() throws {
        let original = SupabaseFollow.fixture()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SupabaseFollow.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.followerID, original.followerID)
        XCTAssertEqual(decoded.followeeID, original.followeeID)
        XCTAssertEqual(decoded.status, original.status)
    }

    // MARK: - SupabaseFollowWithProfile

    func testDecodesFollowWithJoinedProfile() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "follower_id": "660e8400-e29b-41d4-a716-446655440001",
            "followee_id": "770e8400-e29b-41d4-a716-446655440002",
            "status": "pending",
            "created_at": "2025-06-15T10:30:00+00:00",
            "profiles": {
                "display_name": "CoolCatPerson"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let follow = try decoder.decode(SupabaseFollowWithProfile.self, from: json)

        XCTAssertEqual(follow.profiles?.displayName, "CoolCatPerson")
        XCTAssertEqual(follow.status, "pending")
    }

    func testDecodesFollowWithNullProfile() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "follower_id": "660e8400-e29b-41d4-a716-446655440001",
            "followee_id": "770e8400-e29b-41d4-a716-446655440002",
            "status": "pending",
            "created_at": "2025-06-15T10:30:00+00:00",
            "profiles": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let follow = try decoder.decode(SupabaseFollowWithProfile.self, from: json)

        XCTAssertNil(follow.profiles)
    }

    func testFollowWithProfileToDomainMapsDisplayName() {
        let follow = SupabaseFollowWithProfile.fixture(
            status: "pending",
            displayName: "CatLover42"
        ).toDomain()

        XCTAssertEqual(follow.followerDisplayName, "CatLover42")
        XCTAssertTrue(follow.isPending)
    }

    func testFollowWithProfileToDomainNilDisplayName() {
        let follow = SupabaseFollowWithProfile.fixture(status: "pending").toDomain()

        XCTAssertNil(follow.followerDisplayName)
    }
}
