import XCTest
import CatchCore
@testable import catch_app

@MainActor
final class AppRouterTests: XCTestCase {

    // MARK: - routeFromNotification

    func test_routeFromNotification_encounterLiked_returnsEncounterRoute() {
        let router = makeRouter()
        let payload = makePayload(type: .encounterLiked, entityId: "enc-1")
        let route = router.routeFromNotification(payload)
        XCTAssertEqual(route, .encounter(id: "enc-1"))
    }

    func test_routeFromNotification_encounterCommented_returnsEncounterRoute() {
        let router = makeRouter()
        let payload = makePayload(type: .encounterCommented, entityId: "enc-2")
        let route = router.routeFromNotification(payload)
        XCTAssertEqual(route, .encounter(id: "enc-2"))
    }

    func test_routeFromNotification_newFollower_returnsProfileRoute() {
        let router = makeRouter()
        let payload = makePayload(type: .newFollower, entityId: "user-1", actorId: "user-1")
        let route = router.routeFromNotification(payload)
        XCTAssertEqual(route, .profile(id: "user-1"))
    }

    func test_routeFromNotification_newFollower_nilActorId_returnsNil() {
        let router = makeRouter()
        let payload = makePayload(type: .newFollower, entityId: "user-1", actorId: nil)
        let route = router.routeFromNotification(payload)
        XCTAssertNil(route)
    }

    // MARK: - navigate

    func test_navigate_toEncounter_setsFeedTab() {
        let router = makeRouter()
        router.navigate(to: .encounter(id: "enc-1"))
        XCTAssertEqual(router.activeTab, .feed)
    }

    func test_navigate_toProfile_setsFeedTab() {
        let router = makeRouter()
        router.navigate(to: .profile(id: "user-1"))
        XCTAssertEqual(router.activeTab, .feed)
    }

    func test_navigate_setsPendingRoute() {
        let router = makeRouter()
        router.navigate(to: .encounter(id: "enc-1"))
        XCTAssertEqual(router.pendingRoute, .encounter(id: "enc-1"))
    }

    func test_navigate_toProfile_setsPendingRoute() {
        let router = makeRouter()
        router.navigate(to: .profile(id: "user-1"))
        XCTAssertEqual(router.pendingRoute, .profile(id: "user-1"))
    }

    // MARK: - Pending Route Lifecycle

    func test_clearPendingRoute_nilsOut() {
        let router = makeRouter()
        router.navigate(to: .encounter(id: "enc-1"))
        XCTAssertNotNil(router.pendingRoute)
        router.clearPendingRoute()
        XCTAssertNil(router.pendingRoute)
    }

    // MARK: - handleRoute for profile

    func test_handleRoute_profile_setsRoutedProfileId() async {
        let router = makeRouter()
        await router.handleRoute(.profile(id: "user-42"))
        XCTAssertEqual(router.routedProfileId, RoutedProfileId(id: "user-42"))
        XCTAssertNil(router.pendingRoute)
    }

    // MARK: - Initial State

    func test_initialState_noPendingRoute() {
        let router = makeRouter()
        XCTAssertNil(router.pendingRoute)
    }

    func test_initialState_noActiveTab() {
        let router = makeRouter()
        XCTAssertNil(router.activeTab)
    }

    func test_initialState_isNotReady() {
        let router = makeRouter()
        XCTAssertFalse(router.isReady)
    }

    func test_initialState_noRoutedProfileId() {
        let router = makeRouter()
        XCTAssertNil(router.routedProfileId)
    }

    // MARK: - Ready State

    func test_markReady_setsIsReady() {
        let router = makeRouter()
        router.markReady()
        XCTAssertTrue(router.isReady)
    }

    func test_markReady_calledTwice_isIdempotent() {
        let router = makeRouter()
        router.markReady()
        XCTAssertTrue(router.isReady)
        router.markReady()
        XCTAssertTrue(router.isReady)
    }

    func test_markReady_withNoPendingRoute_isNoOp() {
        let router = makeRouter()
        router.markReady()
        XCTAssertTrue(router.isReady)
        XCTAssertNil(router.pendingRoute)
    }

    // MARK: - Helpers

    private let fixedDate = ISO8601DateFormatter().date(
        from: "2026-03-20T12:00:00Z"
    )!

    private func makeRouter() -> AppRouter {
        AppRouter(
            encounterDataService: EncounterDataService(
                encounterRepository: StubEncounterRepository(),
                assetService: StubAssetService(),
                getUserID: { nil }
            ),
            catDataService: CatDataService(
                catRepository: StubCatRepository(),
                encounterRepository: StubEncounterRepository(),
                assetService: StubAssetService(),
                getUserID: { nil }
            )
        )
    }

    private func makePayload(
        type: NotificationType,
        entityId: String,
        actorId: String? = "actor-1"
    ) -> NotificationPayload {
        NotificationPayload(
            notificationType: type,
            entityType: type == .newFollower ? "follow" : "encounter",
            entityId: entityId,
            actorId: actorId,
            createdAt: fixedDate
        )
    }
}

// MARK: - Minimal stubs for router tests

@MainActor
private final class StubEncounterRepository: SupabaseEncounterRepository, @unchecked Sendable {
    func fetchEncounter(id: String) async throws -> SupabaseEncounter? { nil }
    func fetchEncounters(ownerID: String) async throws -> [SupabaseEncounter] { [] }
    func fetchEncounters(catID: String) async throws -> [SupabaseEncounter] { [] }
    func insertEncounter(_ payload: SupabaseEncounterInsertPayload) async throws -> SupabaseEncounter {
        throw NSError(domain: "Stub", code: 0)
    }
    func updateEncounter(id: String, _ payload: SupabaseEncounterUpdatePayload) async throws -> SupabaseEncounter {
        throw NSError(domain: "Stub", code: 0)
    }
    func deleteEncounter(id: String) async throws {}
    func fetchEncounterFeed(ownerID: String, limit: Int, cursor: String?) async throws -> [SupabaseEncounterFeedRow] { [] }
}

@MainActor
private final class StubCatRepository: SupabaseCatRepository, @unchecked Sendable {
    func fetchCat(id: String) async throws -> SupabaseCat? { nil }
    func fetchCats(ownerID: String) async throws -> [SupabaseCat] { [] }
    func fetchCatCounts(ownerIDs: [String]) async throws -> [String: Int] { [:] }
    func insertCat(_ payload: SupabaseCatInsertPayload) async throws -> SupabaseCat {
        throw NSError(domain: "Stub", code: 0)
    }
    func updateCat(id: String, _ payload: SupabaseCatUpdatePayload) async throws -> SupabaseCat {
        throw NSError(domain: "Stub", code: 0)
    }
    func deleteCat(id: String) async throws {}
}

@MainActor
private final class StubAssetService: SupabaseAssetService, @unchecked Sendable {
    func uploadPhoto(_ data: Data, bucket: SupabaseStorageBucket, ownerID: String, fileName: String) async throws -> String { "" }
    func uploadPhotos(_ photos: [Data], bucket: SupabaseStorageBucket, ownerID: String) async throws -> [String] { [] }
    func deletePhoto(bucket: SupabaseStorageBucket, path: String) async throws {}
    func publicURL(bucket: SupabaseStorageBucket, path: String) -> String { "" }
}
