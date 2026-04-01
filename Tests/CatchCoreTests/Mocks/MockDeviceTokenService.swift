import Foundation
@testable import CatchCore

@MainActor
final class MockDeviceTokenService: DeviceTokenServiceProtocol, @unchecked Sendable {
    private(set) var registerCalls = 0
    private(set) var syncTokenCalls: [Data] = []
    private(set) var clearTokenCalls = 0
    private(set) var requestPermissionCalls = 0

    func registerForPushNotifications() {
        registerCalls += 1
    }

    func syncToken(_ token: Data) async {
        syncTokenCalls.append(token)
    }

    func clearToken() async {
        clearTokenCalls += 1
    }

    func requestPermissionIfNeeded() async {
        requestPermissionCalls += 1
    }

    func reset() {
        registerCalls = 0
        syncTokenCalls = []
        clearTokenCalls = 0
        requestPermissionCalls = 0
    }
}
