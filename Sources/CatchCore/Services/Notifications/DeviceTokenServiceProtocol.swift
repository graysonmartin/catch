import Foundation

/// Manages APNs device token registration, syncing, and permission requests.
@MainActor
public protocol DeviceTokenServiceProtocol: Sendable {
    /// Requests the OS to register for remote notifications.
    func registerForPushNotifications()

    /// Converts the raw APNs token data and syncs it to the backend.
    func syncToken(_ token: Data) async

    /// Removes the user's device tokens from the backend (e.g. on sign out).
    func clearToken() async

    /// Checks notification authorization status and requests permission if not yet determined.
    /// If granted, triggers remote notification registration.
    func requestPermissionIfNeeded() async
}
