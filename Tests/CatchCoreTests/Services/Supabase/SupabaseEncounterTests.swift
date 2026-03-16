import XCTest
@testable import CatchCore

final class SupabaseEncounterTests: XCTestCase {

    // MARK: - Decoding

    func testDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "owner_id": "660e8400-e29b-41d4-a716-446655440001",
            "cat_id": "770e8400-e29b-41d4-a716-446655440002",
            "date": "2025-03-10T08:00:00Z",
            "location_name": "back alley",
            "location_lat": 37.7749,
            "location_lng": -122.4194,
            "notes": "sleeping in a box",
            "photo_urls": ["https://example.com/enc1.jpg"],
            "like_count": 5,
            "comment_count": 2,
            "created_at": "2025-03-10T08:00:00Z",
            "updated_at": "2025-03-10T09:00:00Z"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let encounter = try decoder.decode(SupabaseEncounter.self, from: data)

        XCTAssertEqual(encounter.id, UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000"))
        XCTAssertEqual(encounter.ownerID, UUID(uuidString: "660e8400-e29b-41d4-a716-446655440001"))
        XCTAssertEqual(encounter.catID, UUID(uuidString: "770e8400-e29b-41d4-a716-446655440002"))
        XCTAssertEqual(encounter.locationName, "back alley")
        XCTAssertEqual(encounter.locationLat, 37.7749)
        XCTAssertEqual(encounter.locationLng, -122.4194)
        XCTAssertEqual(encounter.notes, "sleeping in a box")
        XCTAssertEqual(encounter.photoUrls, ["https://example.com/enc1.jpg"])
        XCTAssertEqual(encounter.likeCount, 5)
        XCTAssertEqual(encounter.commentCount, 2)
    }

    func testDecodesWithNullOptionalFields() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "owner_id": "660e8400-e29b-41d4-a716-446655440001",
            "cat_id": "770e8400-e29b-41d4-a716-446655440002",
            "date": "2025-03-10T08:00:00Z",
            "location_name": null,
            "location_lat": null,
            "location_lng": null,
            "notes": null,
            "photo_urls": [],
            "like_count": 0,
            "comment_count": 0,
            "created_at": "2025-03-10T08:00:00Z",
            "updated_at": "2025-03-10T08:00:00Z"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let encounter = try decoder.decode(SupabaseEncounter.self, from: data)

        XCTAssertNil(encounter.locationName)
        XCTAssertNil(encounter.locationLat)
        XCTAssertNil(encounter.locationLng)
        XCTAssertNil(encounter.notes)
        XCTAssertTrue(encounter.photoUrls.isEmpty)
        XCTAssertEqual(encounter.likeCount, 0)
        XCTAssertEqual(encounter.commentCount, 0)
    }

    // MARK: - Encoding

    func testEncodesToSnakeCaseJSON() throws {
        let encounter = SupabaseEncounter(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            ownerID: UUID(uuidString: "660e8400-e29b-41d4-a716-446655440001")!,
            catID: UUID(uuidString: "770e8400-e29b-41d4-a716-446655440002")!,
            date: Date(timeIntervalSince1970: 0),
            locationName: "park",
            locationLat: 37.0,
            locationLng: -122.0,
            notes: "friendly",
            photoUrls: [],
            likeCount: 3,
            commentCount: 1,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(encounter)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(dict?["owner_id"])
        XCTAssertNotNil(dict?["cat_id"])
        XCTAssertNotNil(dict?["location_name"])
        XCTAssertNotNil(dict?["location_lat"])
        XCTAssertNotNil(dict?["location_lng"])
        XCTAssertNotNil(dict?["photo_urls"])
        XCTAssertNotNil(dict?["like_count"])
        XCTAssertNotNil(dict?["comment_count"])
        XCTAssertNotNil(dict?["created_at"])
        XCTAssertNotNil(dict?["updated_at"])
    }

    // MARK: - Round Trip

    func testRoundTrip() throws {
        let original = SupabaseEncounter(
            id: UUID(),
            ownerID: UUID(),
            catID: UUID(),
            date: Date(timeIntervalSinceReferenceDate: 700000000),
            locationName: "rooftop",
            locationLat: 40.7128,
            locationLng: -74.0060,
            notes: "was sunbathing",
            photoUrls: ["url1"],
            likeCount: 10,
            commentCount: 3,
            createdAt: Date(timeIntervalSinceReferenceDate: 700000000),
            updatedAt: Date(timeIntervalSinceReferenceDate: 700000000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SupabaseEncounter.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.ownerID, original.ownerID)
        XCTAssertEqual(decoded.catID, original.catID)
        XCTAssertEqual(decoded.locationName, original.locationName)
        XCTAssertEqual(decoded.locationLat, original.locationLat)
        XCTAssertEqual(decoded.locationLng, original.locationLng)
        XCTAssertEqual(decoded.notes, original.notes)
        XCTAssertEqual(decoded.photoUrls, original.photoUrls)
        XCTAssertEqual(decoded.likeCount, original.likeCount)
        XCTAssertEqual(decoded.commentCount, original.commentCount)
    }
}
