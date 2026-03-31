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

    // MARK: - Equatable

    func testEqualItemsAreEqual() {
        let date = Date()
        let a = NotificationItem(
            id: "1",
            notificationType: .encounterLiked,
            actorUserID: nil,
            actorDisplayName: "alice",
            actorAvatarURL: nil,
            encounterId: "enc-1",
            encounterThumbnailURL: nil,
            timestamp: date,
            isRead: false
        )
        let b = NotificationItem(
            id: "1",
            notificationType: .encounterLiked,
            actorUserID: nil,
            actorDisplayName: "alice",
            actorAvatarURL: nil,
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
            actorUserID: nil,
            actorDisplayName: "alice",
            actorAvatarURL: nil,
            encounterId: "enc-1",
            encounterThumbnailURL: nil,
            timestamp: date,
            isRead: false
        )
        let b = NotificationItem(
            id: "1",
            notificationType: .encounterLiked,
            actorUserID: nil,
            actorDisplayName: "alice",
            actorAvatarURL: nil,
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
            actorUserID: "user-456",
            actorDisplayName: "test user",
            actorAvatarURL: nil,
            encounterId: "enc-123",
            encounterThumbnailURL: nil,
            timestamp: Date(),
            isRead: isRead
        )
    }
}
