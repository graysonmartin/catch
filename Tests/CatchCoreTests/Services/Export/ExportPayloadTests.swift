import XCTest
@testable import CatchCore

final class ExportPayloadTests: XCTestCase {

    // MARK: - ExportPayload

    func testPayloadDefaultVersionIsOne() {
        let payload = ExportPayload(cats: [])
        XCTAssertEqual(payload.version, 1)
    }

    func testPayloadEquality() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let cat = makeExportCat(id: "cat-1", createdAt: date)
        let a = ExportPayload(version: 1, exportedAt: date, cats: [cat])
        let b = ExportPayload(version: 1, exportedAt: date, cats: [cat])
        XCTAssertEqual(a, b)
    }

    // MARK: - ExportCat

    func testExportCatCodableRoundTrip() throws {
        let cat = makeExportCat(id: "test-uuid")
        let data = try JSONEncoder.iso8601Encoder.encode(cat)
        let decoded = try JSONDecoder.iso8601Decoder.decode(ExportCat.self, from: data)
        XCTAssertEqual(decoded, cat)
    }

    func testExportCatNilOptionalFields() throws {
        let cat = ExportCat(
            id: "bare",
            name: nil,
            breed: nil,
            estimatedAge: nil,
            locationName: nil,
            locationLat: nil,
            locationLng: nil,
            notes: nil,
            isOwned: false,
            photoUrls: [],
            createdAt: Date(timeIntervalSince1970: 0),
            encounters: []
        )
        let data = try JSONEncoder.iso8601Encoder.encode(cat)
        let decoded = try JSONDecoder.iso8601Decoder.decode(ExportCat.self, from: data)
        XCTAssertEqual(decoded, cat)
        XCTAssertNil(decoded.name)
        XCTAssertNil(decoded.breed)
        XCTAssertNil(decoded.notes)
    }

    // MARK: - ExportEncounter

    func testExportEncounterCodableRoundTrip() throws {
        let encounter = makeExportEncounter(id: "enc-1")
        let data = try JSONEncoder.iso8601Encoder.encode(encounter)
        let decoded = try JSONDecoder.iso8601Decoder.decode(ExportEncounter.self, from: data)
        XCTAssertEqual(decoded, encounter)
    }

    // MARK: - Helpers

    private func makeExportCat(
        id: String,
        createdAt: Date = Date(timeIntervalSince1970: 1_000_000)
    ) -> ExportCat {
        ExportCat(
            id: id,
            name: "whiskers",
            breed: "tabby",
            estimatedAge: "2 years",
            locationName: "park bench",
            locationLat: 37.7749,
            locationLng: -122.4194,
            notes: "friendly",
            isOwned: false,
            photoUrls: ["https://example.com/photo.jpg"],
            createdAt: createdAt,
            encounters: [makeExportEncounter(id: "enc-for-\(id)")]
        )
    }

    private func makeExportEncounter(id: String) -> ExportEncounter {
        ExportEncounter(
            id: id,
            date: Date(timeIntervalSince1970: 1_000_000),
            locationName: "alley",
            locationLat: 40.7128,
            locationLng: -74.0060,
            notes: "saw it again",
            photoUrls: [],
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        )
    }
}

// MARK: - JSON Coder Helpers

private extension JSONEncoder {
    static let iso8601Encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension JSONDecoder {
    static let iso8601Decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
