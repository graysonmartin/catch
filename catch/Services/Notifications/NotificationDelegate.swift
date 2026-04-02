import Foundation
import os
import UIKit
import UserNotifications
import CatchCore

/// Handles APNs registration callbacks and notification tap/presentation events.
///
/// Set as the `UNUserNotificationCenter` delegate early in the app lifecycle.
/// Bridges between the OS notification system and the app's routing layer.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // MARK: - Dependencies

    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "NotificationDelegate")
    private let tokenService: any DeviceTokenServiceProtocol
    private let router: AppRouter

    // MARK: - Init

    init(tokenService: any DeviceTokenServiceProtocol, router: AppRouter) {
        self.tokenService = tokenService
        self.router = router
        super.init()
    }

    // MARK: - Foreground Presentation

    /// Shows a banner when a notification arrives while the app is in the foreground.
    /// Does not auto-navigate — the user taps the banner to navigate.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Tap Handling

    /// Decodes the notification payload and navigates to the appropriate screen.
    /// If the router is not yet ready (cold launch), the route is stored as pending.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        guard let payload = APNsPayloadDecoder.decode(from: userInfo) else {
            completionHandler()
            return
        }

        Task { @MainActor in
            guard let route = router.routeFromNotification(payload) else {
                completionHandler()
                return
            }

            if router.isReady {
                router.navigate(to: route)
            } else {
                router.pendingRoute = route
            }

            completionHandler()
        }
    }

    // MARK: - Token Registration

    /// Called by the AppDelegate when APNs registration succeeds.
    func didRegisterForRemoteNotifications(withDeviceToken token: Data) {
        Task {
            await tokenService.syncToken(token)
        }
    }

    /// Called by the AppDelegate when APNs registration fails.
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        logger.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }
}
