import XCTest
@testable import CatchCore

final class NotificationPayloadTests: XCTestCase {

    // MARK: - Round-trip Encoding

    func test_roundTrip_encounterLiked() throws {
        let payload = makePayload(type: .encounterLiked)
        let decoded = try encodeThenDecode(payload)
        XCTAssertEqual(decoded, payload)
    }

    func test_roundTrip_encounterCommented() throws {
        let payload = makePayload(type: .encounterCommented)
        let decoded = try encodeThenDecode(payload)
        XCTAssertEqual(decoded, payload)
    }

    func test_roundTrip_withNilOptionals() throws {
        let payload = NotificationPayload(
            notificationType: .encounterLiked,
            entityType: "encounter",
            entityId: "enc-123",
            actorId: nil,
            collapseKey: nil,
            createdAt: fixedDate,
            version: 1
        )
        let decoded = try encodeThenDecode(payload)
        XCTAssertEqual(decoded, payload)
        XCTAssertNil(decoded.actorId)
        XCTAssertNil(decoded.collapseKey)
    }

    // MARK: - Snake Case Keys

    func test_jsonKeys_useSnakeCase() throws {
        let payload = makePayload(type: .encounterLiked)
        let data = try encoder.encode(payload)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertNotNil(json["notification_type"])
        XCTAssertNotNil(json["entity_type"])
        XCTAssertNotNil(json["entity_id"])
        XCTAssertNotNil(json["actor_id"])
        XCTAssertNotNil(json["collapse_key"])
        XCTAssertNotNil(json["created_at"])
        XCTAssertNotNil(json["version"])
    }

    // MARK: - NotificationType Raw Values

    func test_notificationType_encounterLiked_rawValue() {
        XCTAssertEqual(NotificationType.encounterLiked.rawValue, "encounter_liked")
    }

    func test_notificationType_encounterCommented_rawValue() {
        XCTAssertEqual(NotificationType.encounterCommented.rawValue, "encounter_commented")
    }

    func test_notificationType_decodesFromRawValue() throws {
        let json = Data("\"encounter_liked\"".utf8)
        let decoded = try JSONDecoder().decode(NotificationType.self, from: json)
        XCTAssertEqual(decoded, .encounterLiked)
    }

    func test_notificationType_invalidRawValue_throws() {
        let json = Data("\"unknown_type\"".utf8)
        XCTAssertThrowsError(
            try JSONDecoder().decode(NotificationType.self, from: json)
        )
    }

    // MARK: - Version

    func test_versionDefaultsToOne() {
        let payload = NotificationPayload(
            notificationType: .encounterLiked,
            entityType: "encounter",
            entityId: "enc-1",
            createdAt: fixedDate
        )
        XCTAssertEqual(payload.version, 1)
    }

    // MARK: - Helpers

    private let fixedDate = ISO8601DateFormatter().date(
        from: "2026-03-20T12:00:00Z"
    )!

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private func makePayload(type: NotificationType) -> NotificationPayload {
        NotificationPayload(
            notificationType: type,
            entityType: "encounter",
            entityId: "enc-abc-123",
            actorId: "user-xyz",
            collapseKey: "enc-abc-123",
            createdAt: fixedDate,
            version: 1
        )
    }

    private func encodeThenDecode(
        _ payload: NotificationPayload
    ) throws -> NotificationPayload {
        let data = try encoder.encode(payload)
        return try decoder.decode(NotificationPayload.self, from: data)
    }
}
