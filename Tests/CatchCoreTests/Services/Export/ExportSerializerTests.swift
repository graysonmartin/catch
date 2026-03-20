import XCTest
@testable import CatchCore

final class ExportSerializerTests: XCTestCase {

    // MARK: - Encode / Decode Round Trip

    func testRoundTrip() throws {
        let original = makePayload()
        let data = try ExportSerializer.encode(original)
        let decoded = try ExportSerializer.decode(data)

        XCTAssertEqual(decoded.version, original.version)
        XCTAssertEqual(decoded.cats.count, original.cats.count)
        XCTAssertEqual(decoded.cats.first?.id, original.cats.first?.id)
        XCTAssertEqual(decoded.cats.first?.name, original.cats.first?.name)
        XCTAssertEqual(decoded.cats.first?.encounters.count, original.cats.first?.encounters.count)
    }

    func testEncodesAsPrettyPrintedJSON() throws {
        let payload = makePayload()
        let data = try ExportSerializer.encode(payload)
        let jsonString = String(data: data, encoding: .utf8)
        // Pretty-printed JSON uses newlines
        XCTAssertTrue(jsonString?.contains("\n") ?? false)
    }

    func testEncodedJSONContainsVersionKey() throws {
        let payload = makePayload()
        let data = try ExportSerializer.encode(payload)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(dict?["version"] as? Int, 1)
    }

    func testDecodeInvalidDataThrows() {
        let badData = Data("not json".utf8)
        XCTAssertThrowsError(try ExportSerializer.decode(badData))
    }

    func testEmptyPayloadRoundTrip() throws {
        let empty = ExportPayload(
            version: 1,
            exportedAt: Date(timeIntervalSince1970: 0),
            cats: []
        )
        let data = try ExportSerializer.encode(empty)
        let decoded = try ExportSerializer.decode(data)
        XCTAssertEqual(decoded.version, 1)
        XCTAssertTrue(decoded.cats.isEmpty)
    }

    // MARK: - File Naming

    func testBackupFileNameFormat() {
        let date = Date(timeIntervalSince1970: 1_710_000_000) // 2024-03-09
        let name = ExportSerializer.backupFileName(date: date)
        XCTAssertTrue(name.hasPrefix("catch-backup-"))
        XCTAssertTrue(name.hasSuffix(".json"))
        // Should contain a date component in yyyy-MM-dd format
        XCTAssertTrue(name.contains("-20"))
    }

    func testBackupFileNameContainsDate() {
        // Use a known date: 2026-03-20
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 20
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(from: components)!
        let name = ExportSerializer.backupFileName(date: date)
        XCTAssertEqual(name, "catch-backup-2026-03-20.json")
    }

    // MARK: - Multiple Cats with Encounters

    func testMultipleCatsRoundTrip() throws {
        let cat1 = ExportCat(
            id: "cat-1",
            name: "whiskers",
            breed: "tabby",
            estimatedAge: nil,
            locationName: "park",
            locationLat: 37.0,
            locationLng: -122.0,
            notes: nil,
            isOwned: true,
            photoUrls: [],
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            encounters: []
        )
        let encounter = ExportEncounter(
            id: "enc-1",
            date: Date(timeIntervalSince1970: 2_000_000),
            locationName: "alley",
            locationLat: 40.0,
            locationLng: -74.0,
            notes: "sleepy",
            photoUrls: ["url1"],
            createdAt: Date(timeIntervalSince1970: 2_000_000)
        )
        let cat2 = ExportCat(
            id: "cat-2",
            name: nil,
            breed: nil,
            estimatedAge: "kitten",
            locationName: nil,
            locationLat: nil,
            locationLng: nil,
            notes: "mystery cat",
            isOwned: false,
            photoUrls: ["url2", "url3"],
            createdAt: Date(timeIntervalSince1970: 1_500_000),
            encounters: [encounter]
        )

        let payload = ExportPayload(
            version: 1,
            exportedAt: Date(timeIntervalSince1970: 3_000_000),
            cats: [cat1, cat2]
        )

        let data = try ExportSerializer.encode(payload)
        let decoded = try ExportSerializer.decode(data)

        XCTAssertEqual(decoded.cats.count, 2)
        XCTAssertEqual(decoded.cats[0].id, "cat-1")
        XCTAssertEqual(decoded.cats[0].name, "whiskers")
        XCTAssertTrue(decoded.cats[0].encounters.isEmpty)

        XCTAssertEqual(decoded.cats[1].id, "cat-2")
        XCTAssertNil(decoded.cats[1].name)
        XCTAssertEqual(decoded.cats[1].encounters.count, 1)
        XCTAssertEqual(decoded.cats[1].encounters[0].id, "enc-1")
        XCTAssertEqual(decoded.cats[1].encounters[0].notes, "sleepy")
    }

    // MARK: - Helpers

    private func makePayload() -> ExportPayload {
        let encounter = ExportEncounter(
            id: "enc-1",
            date: Date(timeIntervalSince1970: 1_000_000),
            locationName: "corner",
            locationLat: 37.0,
            locationLng: -122.0,
            notes: "friendly",
            photoUrls: [],
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        )
        let cat = ExportCat(
            id: "cat-1",
            name: "whiskers",
            breed: "tabby",
            estimatedAge: "2 years",
            locationName: "park",
            locationLat: 37.7749,
            locationLng: -122.4194,
            notes: "loves treats",
            isOwned: false,
            photoUrls: ["https://example.com/photo.jpg"],
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            encounters: [encounter]
        )
        return ExportPayload(
            version: 1,
            exportedAt: Date(timeIntervalSince1970: 2_000_000),
            cats: [cat]
        )
    }
}
