import XCTest
import CatchCore

@MainActor
final class MockInAppNotificationServiceTests: XCTestCase {

    private var sut: MockInAppNotificationService!

    override func setUp() {
        super.setUp()
        sut = MockInAppNotificationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Load

    func testLoadIfNeededSetsHasLoaded() async {
        XCTAssertFalse(sut.hasLoaded)
        await sut.loadIfNeeded()
        XCTAssertTrue(sut.hasLoaded)
        XCTAssertEqual(sut.loadIfNeededCalls, 1)
    }

    func testRefreshIncrementsCalls() async {
        await sut.refresh()
        await sut.refresh()
        XCTAssertEqual(sut.refreshCalls, 2)
    }

    // MARK: - Mark As Read

    func testMarkAsReadUpdatesItem() async {
        sut.notifications = [makeItem(id: "1", isRead: false)]
        sut.unreadCount = 1

        await sut.markAsRead(notificationId: "1")

        XCTAssertTrue(sut.notifications[0].isRead)
        XCTAssertEqual(sut.unreadCount, 0)
        XCTAssertEqual(sut.markAsReadCalls, ["1"])
    }

    func testMarkAsReadWithUnknownIdIsNoOp() async {
        sut.notifications = [makeItem(id: "1", isRead: false)]
        sut.unreadCount = 1

        await sut.markAsRead(notificationId: "unknown")

        XCTAssertFalse(sut.notifications[0].isRead)
        XCTAssertEqual(sut.unreadCount, 1)
    }

    // MARK: - Mark All As Read

    func testMarkAllAsReadUpdatesAllItems() async {
        sut.notifications = [
            makeItem(id: "1", isRead: false),
            makeItem(id: "2", isRead: false),
            makeItem(id: "3", isRead: true),
        ]
        sut.unreadCount = 2

        await sut.markAllAsRead()

        XCTAssertTrue(sut.notifications.allSatisfy(\.isRead))
        XCTAssertEqual(sut.unreadCount, 0)
        XCTAssertEqual(sut.markAllAsReadCalls, 1)
    }

    // MARK: - Reset

    func testResetClearsState() async {
        sut.notifications = [makeItem(id: "1", isRead: false)]
        sut.unreadCount = 1
        await sut.loadIfNeeded()
        await sut.refresh()

        sut.reset()

        XCTAssertTrue(sut.notifications.isEmpty)
        XCTAssertEqual(sut.unreadCount, 0)
        XCTAssertFalse(sut.hasLoaded)
        XCTAssertEqual(sut.loadIfNeededCalls, 0)
        XCTAssertEqual(sut.refreshCalls, 0)
    }

    // MARK: - Helpers

    private func makeItem(id: String, isRead: Bool) -> NotificationItem {
        NotificationItem(
            id: id,
            notificationType: .encounterLiked,
            actorDisplayName: "user",
            actorAvatarURL: nil,
            actorId: "actor-\(id)",
            encounterId: "enc-\(id)",
            encounterThumbnailURL: nil,
            timestamp: Date(),
            isRead: isRead
        )
    }
}
