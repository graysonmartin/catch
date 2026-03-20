import Foundation
import CatchCore

@MainActor
final class AppRouter: ObservableObject {

    // MARK: - Published State

    @Published var pendingRoute: AppRoute?
    @Published var activeTab: ContentTab?

    /// Indicates whether the navigation hierarchy is mounted and ready
    /// to handle route changes. Set to `true` once `ContentView` appears.
    @Published private(set) var isReady = false

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

    func executePendingRoute() {
        // The consuming view reads `pendingRoute` and handles navigation,
        // then calls `clearPendingRoute()` once the destination is shown.
        // This method is the explicit trigger point for deferred routing
        // after the navigation hierarchy is ready.
        guard pendingRoute != nil else { return }
        // Route is already set — the view layer picks it up via @Published.
    }

    func clearPendingRoute() {
        pendingRoute = nil
    }

    /// Called once the navigation hierarchy is mounted and ready to handle routes.
    /// Automatically executes any pending route that was stored during cold launch.
    func markReady() {
        guard !isReady else { return }
        isReady = true
        executePendingRoute()
    }
}
