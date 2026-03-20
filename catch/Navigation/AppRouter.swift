import Foundation
import CatchCore

@MainActor
final class AppRouter: ObservableObject {

    // MARK: - Dependencies

    private let encounterDataService: EncounterDataService
    private let catDataService: CatDataService

    // MARK: - Published State

    @Published var pendingRoute: AppRoute?
    @Published var activeTab: ContentTab?
    @Published var routedEncounterDetail: EncounterDetailData?

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
        }
        pendingRoute = route
    }

    func routeFromNotification(_ payload: NotificationPayload) -> AppRoute? {
        switch payload.notificationType {
        case .encounterLiked, .encounterCommented:
            return .encounter(id: payload.entityId)
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
                print("[AppRouter] Failed to load encounter \(id): \(error.localizedDescription)")
            }
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
