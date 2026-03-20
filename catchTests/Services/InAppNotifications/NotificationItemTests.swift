import XCTest
import CatchCore

@MainActor
final class NotificationItemTests: XCTestCase {

    // MARK: - Action Description

    func testActionDescriptionForLike() {
        let item = makeItem(type: .encounterLiked)
        XCTAssertEqual(item.actionDescription, CatchStrings.Notifications.likedYourEncounter)
    }

    func testActionDescriptionForComment() {
        let item = makeItem(type: .encounterCommented)
        XCTAssertEqual(item.actionDescription, CatchStrings.Notifications.commentedOnYourEncounter)
    }

    func testActionDescriptionForNewFollower() {
        let item = makeItem(type: .newFollower)
        XCTAssertEqual(item.actionDescription, CatchStrings.Notifications.startedFollowingYou)
    }

    // MARK: - withReadState

    func testWithReadStateReturnsCopyWithUpdatedFlag() {
        let item = makeItem(type: .encounterLiked, isRead: false)
        let updated = item.withReadState(true)
        XCTAssertTrue(updated.isRead)
        XCTAssertEqual(updated.id, item.id)
        XCTAssertEqual(updated.notificationType, item.notificationType)
        XCTAssertEqual(updated.actorDisplayName, item.actorDisplayName)
        XCTAssertEqual(updated.actorAvatarURL, item.actorAvatarURL)
        XCTAssertEqual(updated.actorId, item.actorId)
        XCTAssertEqual(updated.encounterId, item.encounterId)
        XCTAssertEqual(updated.encounterThumbnailURL, item.encounterThumbnailURL)
        XCTAssertEqual(updated.timestamp, item.timestamp)
    }

    func testWithReadStateFalseFromTrue() {
        let item = makeItem(type: .encounterLiked, isRead: true)
        let updated = item.withReadState(false)
        XCTAssertFalse(updated.isRead)
    }

    // MARK: - Follow notification fields

    func testFollowNotificationHasNoEncounterId() {
        let item = makeFollowItem()
        XCTAssertNil(item.encounterId)
        XCTAssertNil(item.encounterThumbnailURL)
        XCTAssertEqual(item.actorId, "follower-1")
    }

    // MARK: - Equatable

    func testEqualItemsAreEqual() {
        let date = Date()
        let a = NotificationItem(
            id: "1",
            notificationType: .encounterLiked,
            actorDisplayName: "alice",
            actorAvatarURL: nil,
            actorId: "user-1",
            encounterId: "enc-1",
            encounterThumbnailURL: nil,
            timestamp: date,
            isRead: false
        )
        let b = NotificationItem(
            id: "1",
            notificationType: .encounterLiked,
            actorDisplayName: "alice",
            actorAvatarURL: nil,
            actorId: "user-1",
            encounterId: "enc-1",
            encounterThumbnailURL: nil,
            timestamp: date,
            isRead: false
        )
        XCTAssertEqual(a, b)
    }

    func testDifferentReadStateIsNotEqual() {
        let date = Date()
        let a = NotificationItem(
            id: "1",
            notificationType: .encounterLiked,
            actorDisplayName: "alice",
            actorAvatarURL: nil,
            actorId: "user-1",
            encounterId: "enc-1",
            encounterThumbnailURL: nil,
            timestamp: date,
            isRead: false
        )
        let b = NotificationItem(
            id: "1",
            notificationType: .encounterLiked,
            actorDisplayName: "alice",
            actorAvatarURL: nil,
            actorId: "user-1",
            encounterId: "enc-1",
            encounterThumbnailURL: nil,
            timestamp: date,
            isRead: true
        )
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Identifiable

    func testIdIsStable() {
        let item = makeItem(type: .encounterLiked)
        XCTAssertEqual(item.id, "test-id")
    }

    // MARK: - Helpers

    private func makeItem(
        type: NotificationType,
        isRead: Bool = false
    ) -> NotificationItem {
        NotificationItem(
            id: "test-id",
            notificationType: type,
            actorDisplayName: "test user",
            actorAvatarURL: nil,
            actorId: "actor-1",
            encounterId: type == .newFollower ? nil : "enc-123",
            encounterThumbnailURL: nil,
            timestamp: Date(),
            isRead: isRead
        )
    }

    private func makeFollowItem() -> NotificationItem {
        NotificationItem(
            id: "follow-notif-1",
            notificationType: .newFollower,
            actorDisplayName: "cat_lover_99",
            actorAvatarURL: nil,
            actorId: "follower-1",
            encounterId: nil,
            encounterThumbnailURL: nil,
            timestamp: Date(),
            isRead: false
        )
    }
}
