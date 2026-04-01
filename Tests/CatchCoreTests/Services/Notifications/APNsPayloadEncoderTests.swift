import XCTest
@testable import CatchCore

final class APNsPayloadEncoderTests: XCTestCase {

    // MARK: - Structure

    func test_encode_containsApsKey() throws {
        let result = try encode(makePayload())
        XCTAssertNotNil(result["aps"])
    }

    func test_encode_containsDataKey() throws {
        let result = try encode(makePayload())
        XCTAssertNotNil(result["data"])
    }

    func test_encode_apsContainsAlert() throws {
        let result = try encode(makePayload())
        let aps = try XCTUnwrap(result["aps"] as? [String: Any])
        let alert = try XCTUnwrap(aps["alert"] as? [String: Any])
        XCTAssertEqual(alert["title"] as? String, "test title")
        XCTAssertEqual(alert["body"] as? String, "test body")
    }

    func test_encode_apsContainsSound() throws {
        let result = try encode(makePayload())
        let aps = try XCTUnwrap(result["aps"] as? [String: Any])
        XCTAssertEqual(aps["sound"] as? String, "default")
    }

    func test_encode_apsContainsThreadId_fromCollapseKey() throws {
        let payload = makePayload(collapseKey: "my-thread")
        let result = try encode(payload)
        let aps = try XCTUnwrap(result["aps"] as? [String: Any])
        XCTAssertEqual(aps["thread-id"] as? String, "my-thread")
    }

    func test_encode_apsThreadId_fallsBackToNotificationType() throws {
        let payload = makePayload(collapseKey: nil)
        let result = try encode(payload)
        let aps = try XCTUnwrap(result["aps"] as? [String: Any])
        XCTAssertEqual(aps["thread-id"] as? String, "encounter_liked")
    }

    // MARK: - Data Content

    func test_encode_dataContainsPayloadFields() throws {
        let payload = makePayload()
        let result = try encode(payload)
        let data = try XCTUnwrap(result["data"] as? [String: Any])
        XCTAssertEqual(data["notification_type"] as? String, "encounter_liked")
        XCTAssertEqual(data["entity_type"] as? String, "encounter")
        XCTAssertEqual(data["entity_id"] as? String, "enc-123")
        XCTAssertEqual(data["actor_id"] as? String, "user-456")
        XCTAssertEqual(data["version"] as? Int, 1)
    }

    // MARK: - Custom Sound

    func test_encode_customSound() throws {
        let result = try APNsPayloadEncoder.encode(
            makePayload(),
            title: "t",
            body: "b",
            sound: "meow.caf"
        )
        let aps = try XCTUnwrap(result["aps"] as? [String: Any])
        XCTAssertEqual(aps["sound"] as? String, "meow.caf")
    }

    // MARK: - Helpers

    private let fixedDate = ISO8601DateFormatter().date(
        from: "2026-03-20T12:00:00Z"
    )!

    private func makePayload(collapseKey: String? = "enc-123") -> NotificationPayload {
        NotificationPayload(
            notificationType: .encounterLiked,
            entityType: "encounter",
            entityId: "enc-123",
            actorId: "user-456",
            collapseKey: collapseKey,
            createdAt: fixedDate,
            version: 1
        )
    }

    private func encode(_ payload: NotificationPayload) throws -> [String: Any] {
        try APNsPayloadEncoder.encode(payload, title: "test title", body: "test body")
    }
}
