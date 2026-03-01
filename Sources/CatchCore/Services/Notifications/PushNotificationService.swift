import Foundation

@MainActor
public protocol PushNotificationService: Observable, Sendable {
    var isRegistered: Bool { get }

    func requestAuthorization() async throws -> Bool
    func setupSubscriptions(for ownerID: String) async throws
    func removeAllSubscriptions() async throws
    func handleNotification(userInfo: [String: Any]) async
}
