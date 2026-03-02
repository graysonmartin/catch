import Foundation
@testable import CatchCore

final class MockRateLimiterService: RateLimiterService, @unchecked Sendable {
    private(set) var checkAndRecordCalls: [RateLimitedAction] = []
    private(set) var resetCalls: Int = 0
    private(set) var resetActionCalls: [RateLimitedAction] = []

    var stubbedResult: RateLimitResult = .allowed
    var stubbedResults: [RateLimitedAction: RateLimitResult] = [:]

    func checkAndRecord(action: RateLimitedAction) -> RateLimitResult {
        checkAndRecordCalls.append(action)
        return stubbedResults[action] ?? stubbedResult
    }

    func reset() {
        resetCalls += 1
        checkAndRecordCalls = []
    }

    func reset(action: RateLimitedAction) {
        resetActionCalls.append(action)
    }
}
