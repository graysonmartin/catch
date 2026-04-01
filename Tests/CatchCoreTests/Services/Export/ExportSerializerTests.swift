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
        XCTAssertEqual(decoded.cats.first?.name, original.cats.first?.name)
        XCTAssertEqual(decoded.cats.first?.encounters.count, original.cats.first?.encounters.count)
    }

    func testEncodesAsPrettyPrintedJSON() throws {
        let payload = makePayload()
        let data = try ExportSerializer.encode(payload)
        let jsonString = String(data: data, encoding: .utf8)
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
        XCTAssertTrue(name.contains("-20"))
    }

    func testBackupFileNameContainsDate() {
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
            name: "whiskers",
            breed: "tabby",
            estimatedAge: nil,
            locationName: "park",
            locationLat: 37.0,
            locationLng: -122.0,
            notes: nil,
            isOwned: true,
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            encounters: []
        )
        let encounter = ExportEncounter(
            date: Date(timeIntervalSince1970: 2_000_000),
            locationName: "alley",
            locationLat: 40.0,
            locationLng: -74.0,
            notes: "sleepy",
            createdAt: Date(timeIntervalSince1970: 2_000_000)
        )
        let cat2 = ExportCat(
            name: nil,
            breed: nil,
            estimatedAge: "kitten",
            locationName: nil,
            locationLat: nil,
            locationLng: nil,
            notes: "mystery cat",
            isOwned: false,
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
        XCTAssertEqual(decoded.cats[0].name, "whiskers")
        XCTAssertTrue(decoded.cats[0].encounters.isEmpty)

        XCTAssertNil(decoded.cats[1].name)
        XCTAssertEqual(decoded.cats[1].encounters.count, 1)
        XCTAssertEqual(decoded.cats[1].encounters[0].notes, "sleepy")
    }

    // MARK: - Helpers

    private func makePayload() -> ExportPayload {
        let encounter = ExportEncounter(
            date: Date(timeIntervalSince1970: 1_000_000),
            locationName: "corner",
            locationLat: 37.0,
            locationLng: -122.0,
            notes: "friendly",
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        )
        let cat = ExportCat(
            name: "whiskers",
            breed: "tabby",
            estimatedAge: "2 years",
            locationName: "park",
            locationLat: 37.7749,
            locationLng: -122.4194,
            notes: "loves treats",
            isOwned: false,
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
