import XCTest
@testable import CatchCore

@MainActor
final class NotificationPayloadTests: XCTestCase {

    // MARK: - Subscription ID Generation

    func testEncounterSubscriptionID() {
        let id = NotificationPayload.encounterSubscriptionID(for: "user-123")
        XCTAssertEqual(id, "new-encounter-user-123")
    }

    func testLikeSubscriptionID() {
        let id = NotificationPayload.likeSubscriptionID(for: "user-456")
        XCTAssertEqual(id, "encounter-liked-user-456")
    }

    func testCommentSubscriptionID() {
        let id = NotificationPayload.commentSubscriptionID(for: "user-789")
        XCTAssertEqual(id, "encounter-commented-user-789")
    }

    // MARK: - Event Type Parsing

    func testEventTypeForEncounterSubscription() {
        let eventType = NotificationPayload.eventType(for: "new-encounter-user-123")
        XCTAssertEqual(eventType, .newEncounter)
    }

    func testEventTypeForLikeSubscription() {
        let eventType = NotificationPayload.eventType(for: "encounter-liked-user-456")
        XCTAssertEqual(eventType, .encounterLiked)
    }

    func testEventTypeForCommentSubscription() {
        let eventType = NotificationPayload.eventType(for: "encounter-commented-user-789")
        XCTAssertEqual(eventType, .encounterCommented)
    }

    func testEventTypeForUnknownSubscription() {
        let eventType = NotificationPayload.eventType(for: "some-random-id")
        XCTAssertNil(eventType)
    }

    func testEventTypeForEmptyString() {
        let eventType = NotificationPayload.eventType(for: "")
        XCTAssertNil(eventType)
    }

    // MARK: - Subscription ID Prefixes

    func testEncounterPrefixIsConsistent() {
        let id = NotificationPayload.encounterSubscriptionID(for: "test")
        XCTAssertTrue(id.hasPrefix(NotificationPayload.encounterSubscriptionPrefix))
    }

    func testLikePrefixIsConsistent() {
        let id = NotificationPayload.likeSubscriptionID(for: "test")
        XCTAssertTrue(id.hasPrefix(NotificationPayload.likeSubscriptionPrefix))
    }

    func testCommentPrefixIsConsistent() {
        let id = NotificationPayload.commentSubscriptionID(for: "test")
        XCTAssertTrue(id.hasPrefix(NotificationPayload.commentSubscriptionPrefix))
    }

    // MARK: - Equatable

    func testPayloadEquality() {
        let payload1 = NotificationPayload(eventType: .newEncounter, subscriptionID: "sub-1")
        let payload2 = NotificationPayload(eventType: .newEncounter, subscriptionID: "sub-1")
        XCTAssertEqual(payload1, payload2)
    }

    func testPayloadInequality() {
        let payload1 = NotificationPayload(eventType: .newEncounter, subscriptionID: "sub-1")
        let payload2 = NotificationPayload(eventType: .encounterLiked, subscriptionID: "sub-1")
        XCTAssertNotEqual(payload1, payload2)
    }

    // MARK: - Event Type Raw Values

    func testEventTypeRawValues() {
        XCTAssertEqual(NotificationEventType.newEncounter.rawValue, "new_encounter")
        XCTAssertEqual(NotificationEventType.encounterLiked.rawValue, "encounter_liked")
        XCTAssertEqual(NotificationEventType.encounterCommented.rawValue, "encounter_commented")
    }
}
