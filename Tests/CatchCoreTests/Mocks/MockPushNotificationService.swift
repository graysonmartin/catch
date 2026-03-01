import Foundation
import Observation
@testable import CatchCore

@Observable
@MainActor
final class MockPushNotificationService: PushNotificationService {
    var isRegistered = false

    private(set) var requestAuthorizationCalls = 0
    private(set) var setupSubscriptionsCalls: [String] = []
    private(set) var removeAllSubscriptionsCalls = 0
    private(set) var handleNotificationCalls: [[String: Any]] = []

    var stubbedAuthorizationResult = true
    var authorizationError: PushNotificationError?
    var setupError: PushNotificationError?

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCalls += 1
        if let error = authorizationError { throw error }
        isRegistered = stubbedAuthorizationResult
        return stubbedAuthorizationResult
    }

    func setupSubscriptions(for ownerID: String) async throws {
        setupSubscriptionsCalls.append(ownerID)
        if let error = setupError { throw error }
    }

    func removeAllSubscriptions() async throws {
        removeAllSubscriptionsCalls += 1
    }

    func handleNotification(userInfo: [String: Any]) async {
        handleNotificationCalls.append(userInfo)
    }

    func reset() {
        isRegistered = false
        requestAuthorizationCalls = 0
        setupSubscriptionsCalls = []
        removeAllSubscriptionsCalls = 0
        handleNotificationCalls = []
        stubbedAuthorizationResult = true
        authorizationError = nil
        setupError = nil
    }
}
