import XCTest
import CatchCore
@testable import catch_app

@MainActor
final class AppRouterTests: XCTestCase {

    // MARK: - routeFromNotification

    func test_routeFromNotification_encounterLiked_returnsEncounterRoute() {
        let router = AppRouter()
        let payload = makePayload(type: .encounterLiked, entityId: "enc-1")
        let route = router.routeFromNotification(payload)
        XCTAssertEqual(route, .encounter(id: "enc-1"))
    }

    func test_routeFromNotification_encounterCommented_returnsEncounterRoute() {
        let router = AppRouter()
        let payload = makePayload(type: .encounterCommented, entityId: "enc-2")
        let route = router.routeFromNotification(payload)
        XCTAssertEqual(route, .encounter(id: "enc-2"))
    }

    // MARK: - navigate

    func test_navigate_toEncounter_setsFeedTab() {
        let router = AppRouter()
        router.navigate(to: .encounter(id: "enc-1"))
        XCTAssertEqual(router.activeTab, .feed)
    }

    func test_navigate_setsPendingRoute() {
        let router = AppRouter()
        router.navigate(to: .encounter(id: "enc-1"))
        XCTAssertEqual(router.pendingRoute, .encounter(id: "enc-1"))
    }

    // MARK: - Pending Route Lifecycle

    func test_clearPendingRoute_nilsOut() {
        let router = AppRouter()
        router.navigate(to: .encounter(id: "enc-1"))
        XCTAssertNotNil(router.pendingRoute)
        router.clearPendingRoute()
        XCTAssertNil(router.pendingRoute)
    }

    func test_executePendingRoute_preservesRoute() {
        let router = AppRouter()
        router.navigate(to: .encounter(id: "enc-1"))
        router.executePendingRoute()
        XCTAssertEqual(router.pendingRoute, .encounter(id: "enc-1"))
    }

    func test_executePendingRoute_withNoPending_isNoOp() {
        let router = AppRouter()
        XCTAssertNil(router.pendingRoute)
        router.executePendingRoute()
        XCTAssertNil(router.pendingRoute)
    }

    // MARK: - Initial State

    func test_initialState_noPendingRoute() {
        let router = AppRouter()
        XCTAssertNil(router.pendingRoute)
    }

    func test_initialState_noActiveTab() {
        let router = AppRouter()
        XCTAssertNil(router.activeTab)
    }

    func test_initialState_isNotReady() {
        let router = AppRouter()
        XCTAssertFalse(router.isReady)
    }

    // MARK: - Ready State

    func test_markReady_setsIsReady() {
        let router = AppRouter()
        router.markReady()
        XCTAssertTrue(router.isReady)
    }

    func test_markReady_executesDeferredRoute() {
        let router = AppRouter()
        // Simulate a cold-launch pending route set before the UI is ready
        router.pendingRoute = .encounter(id: "deferred-1")
        XCTAssertFalse(router.isReady)

        router.markReady()

        XCTAssertTrue(router.isReady)
        // The route should still be present for the view to consume
        XCTAssertEqual(router.pendingRoute, .encounter(id: "deferred-1"))
    }

    func test_markReady_calledTwice_isIdempotent() {
        let router = AppRouter()
        router.markReady()
        XCTAssertTrue(router.isReady)
        router.markReady()
        XCTAssertTrue(router.isReady)
    }

    func test_markReady_withNoPendingRoute_isNoOp() {
        let router = AppRouter()
        router.markReady()
        XCTAssertTrue(router.isReady)
        XCTAssertNil(router.pendingRoute)
    }

    // MARK: - Helpers

    private let fixedDate = ISO8601DateFormatter().date(
        from: "2026-03-20T12:00:00Z"
    )!

    private func makePayload(
        type: NotificationType,
        entityId: String
    ) -> NotificationPayload {
        NotificationPayload(
            notificationType: type,
            entityType: "encounter",
            entityId: entityId,
            createdAt: fixedDate
        )
    }
}
