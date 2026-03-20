import XCTest
@testable import CatchCore

final class APNsPayloadDecoderTests: XCTestCase {

    // MARK: - Decoding from data key

    func test_decode_fromDataKey() {
        let userInfo = makeUserInfo()
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.notificationType, .encounterLiked)
        XCTAssertEqual(result?.entityType, "encounter")
        XCTAssertEqual(result?.entityId, "enc-123")
        XCTAssertEqual(result?.actorId, "user-456")
        XCTAssertEqual(result?.version, 1)
    }

    func test_decode_fromDataKey_encounterCommented() {
        var data = makeDataDict()
        data["notification_type"] = "encounter_commented"
        let userInfo: [AnyHashable: Any] = [
            "aps": ["alert": ["title": "t", "body": "b"]],
            "data": data
        ]
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertEqual(result?.notificationType, .encounterCommented)
    }

    func test_decode_fromDataKey_newFollower() {
        let data: [String: Any] = [
            "notification_type": "new_follower",
            "entity_type": "follow",
            "entity_id": "user-789",
            "actor_id": "user-789",
            "created_at": "2026-03-20T12:00:00Z",
            "version": 1
        ]
        let userInfo: [AnyHashable: Any] = [
            "aps": ["alert": ["title": "new follower", "body": "someone followed you"]],
            "data": data
        ]
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.notificationType, .newFollower)
        XCTAssertEqual(result?.entityType, "follow")
        XCTAssertEqual(result?.entityId, "user-789")
        XCTAssertEqual(result?.actorId, "user-789")
    }

    // MARK: - Fallback to top-level keys

    func test_decode_fromTopLevel_whenNoDataKey() {
        var userInfo: [AnyHashable: Any] = makeDataDict()
        userInfo["aps"] = ["alert": ["title": "t", "body": "b"]]
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.entityId, "enc-123")
    }

    // MARK: - Malformed Payloads

    func test_decode_emptyUserInfo_returnsNil() {
        let result = APNsPayloadDecoder.decode(from: [:])
        XCTAssertNil(result)
    }

    func test_decode_missingRequiredFields_returnsNil() {
        let userInfo: [AnyHashable: Any] = [
            "data": ["notification_type": "encounter_liked"]
        ]
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertNil(result)
    }

    func test_decode_invalidNotificationType_returnsNil() {
        var data = makeDataDict()
        data["notification_type"] = "unknown_type"
        let userInfo: [AnyHashable: Any] = ["data": data]
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertNil(result)
    }

    func test_decode_dataIsNotDictionary_returnsNil() {
        let userInfo: [AnyHashable: Any] = ["data": "not a dict"]
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertNil(result)
    }

    func test_decode_onlyApsKey_returnsNil() {
        let userInfo: [AnyHashable: Any] = [
            "aps": ["alert": ["title": "t", "body": "b"]]
        ]
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertNil(result)
    }

    // MARK: - Optional Fields

    func test_decode_nilOptionalFields() {
        var data = makeDataDict()
        data.removeValue(forKey: "actor_id")
        data.removeValue(forKey: "collapse_key")
        let userInfo: [AnyHashable: Any] = ["data": data]
        let result = APNsPayloadDecoder.decode(from: userInfo)
        XCTAssertNotNil(result)
        XCTAssertNil(result?.actorId)
        XCTAssertNil(result?.collapseKey)
    }

    // MARK: - Round-trip with Encoder

    func test_roundTrip_encodeThenDecode() throws {
        let original = NotificationPayload(
            notificationType: .encounterCommented,
            entityType: "encounter",
            entityId: "enc-round",
            actorId: "user-trip",
            collapseKey: "thread-1",
            createdAt: fixedDate,
            version: 2
        )
        let encoded = try APNsPayloadEncoder.encode(
            original,
            title: "New comment",
            body: "Someone commented"
        )
        let decoded = APNsPayloadDecoder.decode(from: encoded)
        XCTAssertEqual(decoded, original)
    }

    func test_roundTrip_newFollower_encodeThenDecode() throws {
        let original = NotificationPayload(
            notificationType: .newFollower,
            entityType: "follow",
            entityId: "user-follow",
            actorId: "user-follow",
            collapseKey: "follow-1",
            createdAt: fixedDate,
            version: 1
        )
        let encoded = try APNsPayloadEncoder.encode(
            original,
            title: "new follower",
            body: "someone started following you"
        )
        let decoded = APNsPayloadDecoder.decode(from: encoded)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Helpers

    private let fixedDate = ISO8601DateFormatter().date(
        from: "2026-03-20T12:00:00Z"
    )!

    private func makeDataDict() -> [String: Any] {
        [
            "notification_type": "encounter_liked",
            "entity_type": "encounter",
            "entity_id": "enc-123",
            "actor_id": "user-456",
            "collapse_key": "enc-123",
            "created_at": "2026-03-20T12:00:00Z",
            "version": 1
        ]
    }

    private func makeUserInfo() -> [AnyHashable: Any] {
        [
            "aps": [
                "alert": ["title": "test", "body": "test body"],
                "sound": "default"
            ],
            "data": makeDataDict()
        ]
    }
}
