import UIKit

/// Minimal UIApplicationDelegate that forwards APNs registration callbacks
/// to the `NotificationDelegate`.
///
/// Used via `@UIApplicationDelegateAdaptor` in `catchApp`.
final class CatchAppDelegate: NSObject, UIApplicationDelegate {

    /// Set by the App struct after creating the notification delegate.
    var notificationDelegate: NotificationDelegate?

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        notificationDelegate?.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        notificationDelegate?.didFailToRegisterForRemoteNotifications(withError: error)
    }
}
