import XCTest
@testable import CatchCore

final class SupabaseCatTests: XCTestCase {

    // MARK: - Decoding

    func testDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "owner_id": "660e8400-e29b-41d4-a716-446655440001",
            "name": "whiskers",
            "breed": "tabby",
            "estimated_age": "2 years",
            "location_name": "park bench",
            "location_lat": 37.7749,
            "location_lng": -122.4194,
            "notes": "loves chin scratches",
            "is_owned": false,
            "photo_urls": ["https://example.com/cat1.jpg"],
            "created_at": "2025-01-15T10:30:00Z",
            "updated_at": "2025-06-01T14:00:00Z"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let cat = try decoder.decode(SupabaseCat.self, from: data)

        XCTAssertEqual(cat.id, UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000"))
        XCTAssertEqual(cat.ownerID, UUID(uuidString: "660e8400-e29b-41d4-a716-446655440001"))
        XCTAssertEqual(cat.name, "whiskers")
        XCTAssertEqual(cat.breed, "tabby")
        XCTAssertEqual(cat.estimatedAge, "2 years")
        XCTAssertEqual(cat.locationName, "park bench")
        XCTAssertEqual(cat.locationLat, 37.7749)
        XCTAssertEqual(cat.locationLng, -122.4194)
        XCTAssertEqual(cat.notes, "loves chin scratches")
        XCTAssertFalse(cat.isOwned)
        XCTAssertEqual(cat.photoUrls, ["https://example.com/cat1.jpg"])
    }

    func testDecodesWithNullOptionalFields() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "owner_id": "660e8400-e29b-41d4-a716-446655440001",
            "name": "",
            "breed": null,
            "estimated_age": null,
            "location_name": null,
            "location_lat": null,
            "location_lng": null,
            "notes": null,
            "is_owned": true,
            "photo_urls": [],
            "created_at": "2025-01-15T10:30:00Z",
            "updated_at": "2025-01-15T10:30:00Z"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let cat = try decoder.decode(SupabaseCat.self, from: data)

        XCTAssertEqual(cat.name, "")
        XCTAssertNil(cat.breed)
        XCTAssertNil(cat.estimatedAge)
        XCTAssertNil(cat.locationName)
        XCTAssertNil(cat.locationLat)
        XCTAssertNil(cat.locationLng)
        XCTAssertNil(cat.notes)
        XCTAssertTrue(cat.isOwned)
        XCTAssertTrue(cat.photoUrls.isEmpty)
    }

    // MARK: - Encoding

    func testEncodesToSnakeCaseJSON() throws {
        let cat = SupabaseCat(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            ownerID: UUID(uuidString: "660e8400-e29b-41d4-a716-446655440001")!,
            name: "whiskers",
            breed: "tabby",
            estimatedAge: "2 years",
            locationName: "park",
            locationLat: 37.0,
            locationLng: -122.0,
            notes: "friendly",
            isOwned: false,
            photoUrls: [],
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(cat)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(dict?["owner_id"])
        XCTAssertNotNil(dict?["estimated_age"])
        XCTAssertNotNil(dict?["location_name"])
        XCTAssertNotNil(dict?["location_lat"])
        XCTAssertNotNil(dict?["location_lng"])
        XCTAssertNotNil(dict?["is_owned"])
        XCTAssertNotNil(dict?["photo_urls"])
        XCTAssertNotNil(dict?["created_at"])
        XCTAssertNotNil(dict?["updated_at"])
    }

    // MARK: - Round Trip

    func testRoundTrip() throws {
        let original = SupabaseCat(
            id: UUID(),
            ownerID: UUID(),
            name: "round trip cat",
            breed: "siamese",
            estimatedAge: "3 years",
            locationName: "alley",
            locationLat: 40.7128,
            locationLng: -74.0060,
            notes: "hissed at me",
            isOwned: true,
            photoUrls: ["url1", "url2"],
            createdAt: Date(timeIntervalSinceReferenceDate: 700000000),
            updatedAt: Date(timeIntervalSinceReferenceDate: 700000000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SupabaseCat.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.ownerID, original.ownerID)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.breed, original.breed)
        XCTAssertEqual(decoded.estimatedAge, original.estimatedAge)
        XCTAssertEqual(decoded.locationName, original.locationName)
        XCTAssertEqual(decoded.locationLat, original.locationLat)
        XCTAssertEqual(decoded.locationLng, original.locationLng)
        XCTAssertEqual(decoded.notes, original.notes)
        XCTAssertEqual(decoded.isOwned, original.isOwned)
        XCTAssertEqual(decoded.photoUrls, original.photoUrls)
    }
}
