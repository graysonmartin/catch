import Foundation
import os
import CatchCore

@MainActor
final class AppRouter: ObservableObject {

    // MARK: - Dependencies

    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "AppRouter")
    private let encounterDataService: EncounterDataService
    private let catDataService: CatDataService

    // MARK: - Published State

    @Published var pendingRoute: AppRoute?
    @Published var activeTab: ContentTab?
    @Published var routedEncounterDetail: EncounterDetailData?
    @Published var routedProfileId: RoutedProfileId?

    /// Indicates whether the navigation hierarchy is mounted and ready
    /// to handle route changes. Set to `true` once `ContentView` appears.
    @Published private(set) var isReady = false

    // MARK: - Init

    init(encounterDataService: EncounterDataService, catDataService: CatDataService) {
        self.encounterDataService = encounterDataService
        self.catDataService = catDataService
    }

    // MARK: - Navigation

    func navigate(to route: AppRoute) {
        switch route {
        case .encounter:
            activeTab = .feed
        case .profile:
            activeTab = .feed
        }
        pendingRoute = route
    }

    func routeFromNotification(_ payload: NotificationPayload) -> AppRoute? {
        switch payload.notificationType {
        case .encounterLiked, .encounterCommented:
            return .encounter(id: payload.entityId)
        case .newFollower:
            guard let actorId = payload.actorId else { return nil }
            return .profile(id: actorId)
        }
    }

    // MARK: - Route Handling

    func handleRoute(_ route: AppRoute) async {
        switch route {
        case .encounter(let id):
            clearPendingRoute()
            do {
                guard let encounter = try await encounterDataService.fetchEncounter(id: id) else { return }
                let cat = try? await catDataService.fetchCat(id: encounter.catID)
                routedEncounterDetail = EncounterDetailData(supabase: encounter, cat: cat)
            } catch {
                logger.error("Failed to load encounter \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        case .profile(let id):
            clearPendingRoute()
            routedProfileId = RoutedProfileId(id: id)
        }
    }

    func clearPendingRoute() {
        pendingRoute = nil
    }

    /// Called once the navigation hierarchy is mounted and ready to handle routes.
    /// Automatically executes any pending route that was stored during cold launch.
    func markReady() {
        guard !isReady else { return }
        isReady = true
        guard let route = pendingRoute else { return }
        Task { await handleRoute(route) }
    }
}
