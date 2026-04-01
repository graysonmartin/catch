import Foundation
@testable import CatchCore

/// A mock rate limiter for testing. By default, allows all actions.
final class MockRateLimiter: RateLimiting, @unchecked Sendable {
    private let lock = NSLock()
    private var blockedActions: Set<RateLimitAction> = []
    private(set) var recordedActions: [RateLimitAction] = []
    private(set) var checkCount = 0

    func checkAllowed(_ action: RateLimitAction) throws {
        lock.lock()
        defer { lock.unlock() }
        checkCount += 1
        if blockedActions.contains(action) {
            throw RateLimitError.throttled(action: action, retryAfter: 1.0)
        }
    }

    func recordAction(_ action: RateLimitAction) {
        lock.lock()
        defer { lock.unlock() }
        recordedActions.append(action)
    }

    func reset(_ action: RateLimitAction) {
        lock.lock()
        defer { lock.unlock() }
        recordedActions.removeAll { $0 == action }
        blockedActions.remove(action)
    }

    func resetAll() {
        lock.lock()
        defer { lock.unlock() }
        recordedActions.removeAll()
        blockedActions.removeAll()
    }

    // MARK: - Test Helpers

    func blockAction(_ action: RateLimitAction) {
        lock.lock()
        defer { lock.unlock() }
        blockedActions.insert(action)
    }

    func allowAction(_ action: RateLimitAction) {
        lock.lock()
        defer { lock.unlock() }
        blockedActions.remove(action)
    }
}
