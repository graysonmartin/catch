import XCTest
@testable import CatchCore

@MainActor
final class RateLimiterTests: XCTestCase {

    // MARK: - Debounce (minIntervalSeconds)

    func test_debounce_allowsFirstAction() throws {
        let clock = MockClock()
        let config = RateLimitConfig(maxActions: 100, windowSeconds: 60, minIntervalSeconds: 0.5)
        let limiter = RateLimiter(configs: [.like: config], clock: clock)

        XCTAssertNoThrow(try limiter.checkAllowed(.like))
    }

    func test_debounce_blocksRapidSecondAction() throws {
        let clock = MockClock()
        let config = RateLimitConfig(maxActions: 100, windowSeconds: 60, minIntervalSeconds: 0.5)
        let limiter = RateLimiter(configs: [.like: config], clock: clock)

        try limiter.checkAllowed(.like)
        limiter.recordAction(.like)

        clock.advance(by: 0.2) // Only 0.2s elapsed, need 0.5s

        XCTAssertThrowsError(try limiter.checkAllowed(.like)) { error in
            guard let rateLimitError = error as? RateLimitError else {
                XCTFail("Expected RateLimitError, got \(error)")
                return
            }
            if case .throttled(let action, let retryAfter) = rateLimitError {
                XCTAssertEqual(action, .like)
                XCTAssertGreaterThan(retryAfter, 0)
                XCTAssertLessThanOrEqual(retryAfter, 0.5)
            } else {
                XCTFail("Expected .throttled, got \(rateLimitError)")
            }
        }
    }

    func test_debounce_allowsActionAfterInterval() throws {
        let clock = MockClock()
        let config = RateLimitConfig(maxActions: 100, windowSeconds: 60, minIntervalSeconds: 0.5)
        let limiter = RateLimiter(configs: [.like: config], clock: clock)

        try limiter.checkAllowed(.like)
        limiter.recordAction(.like)

        clock.advance(by: 0.6) // Past the 0.5s debounce interval

        XCTAssertNoThrow(try limiter.checkAllowed(.like))
    }

    // MARK: - Throttle (maxActions per window)

    func test_throttle_allowsUpToMaxActions() throws {
        let clock = MockClock()
        let config = RateLimitConfig(maxActions: 3, windowSeconds: 60, minIntervalSeconds: 0)
        let limiter = RateLimiter(configs: [.follow: config], clock: clock)

        for _ in 0..<3 {
            try limiter.checkAllowed(.follow)
            limiter.recordAction(.follow)
        }

        // 4th action should be blocked
        XCTAssertThrowsError(try limiter.checkAllowed(.follow)) { error in
            guard let rateLimitError = error as? RateLimitError else {
                XCTFail("Expected RateLimitError, got \(error)")
                return
            }
            if case .throttled(let action, _) = rateLimitError {
                XCTAssertEqual(action, .follow)
            } else {
                XCTFail("Expected .throttled, got \(rateLimitError)")
            }
        }
    }

    func test_throttle_allowsActionsAfterWindowExpires() throws {
        let clock = MockClock()
        let config = RateLimitConfig(maxActions: 2, windowSeconds: 10, minIntervalSeconds: 0)
        let limiter = RateLimiter(configs: [.comment: config], clock: clock)

        try limiter.checkAllowed(.comment)
        limiter.recordAction(.comment)

        try limiter.checkAllowed(.comment)
        limiter.recordAction(.comment)

        // At capacity — should be blocked
        XCTAssertThrowsError(try limiter.checkAllowed(.comment))

        // Advance past the window
        clock.advance(by: 11)

        // Should be allowed again — old entries expired
        XCTAssertNoThrow(try limiter.checkAllowed(.comment))
    }

    // MARK: - Combined Debounce + Throttle

    func test_combinedLimits_debounceBlocksBeforeThrottle() throws {
        let clock = MockClock()
        let config = RateLimitConfig(maxActions: 10, windowSeconds: 60, minIntervalSeconds: 2)
        let limiter = RateLimiter(configs: [.comment: config], clock: clock)

        try limiter.checkAllowed(.comment)
        limiter.recordAction(.comment)

        clock.advance(by: 0.5) // Only 0.5s, need 2s

        // Should be blocked by debounce even though throttle has room
        XCTAssertThrowsError(try limiter.checkAllowed(.comment))
    }

    // MARK: - Different Action Types

    func test_differentActionTypes_trackedIndependently() throws {
        let clock = MockClock()
        let configs: [RateLimitAction: RateLimitConfig] = [
            .like: RateLimitConfig(maxActions: 1, windowSeconds: 60, minIntervalSeconds: 0),
            .comment: RateLimitConfig(maxActions: 1, windowSeconds: 60, minIntervalSeconds: 0)
        ]
        let limiter = RateLimiter(configs: configs, clock: clock)

        try limiter.checkAllowed(.like)
        limiter.recordAction(.like)

        // Like is at capacity, but comment should still be allowed
        XCTAssertThrowsError(try limiter.checkAllowed(.like))
        XCTAssertNoThrow(try limiter.checkAllowed(.comment))
    }

    // MARK: - Unconfigured Action

    func test_unconfiguredAction_isAlwaysAllowed() throws {
        let limiter = RateLimiter(configs: [:])

        // No config for .search, should always pass
        XCTAssertNoThrow(try limiter.checkAllowed(.search))
        limiter.recordAction(.search)
        XCTAssertNoThrow(try limiter.checkAllowed(.search))
    }

    // MARK: - Reset

    func test_reset_clearsHistoryForAction() throws {
        let clock = MockClock()
        let config = RateLimitConfig(maxActions: 1, windowSeconds: 60, minIntervalSeconds: 0)
        let limiter = RateLimiter(configs: [.like: config], clock: clock)

        try limiter.checkAllowed(.like)
        limiter.recordAction(.like)
        XCTAssertThrowsError(try limiter.checkAllowed(.like))

        limiter.reset(.like)

        XCTAssertNoThrow(try limiter.checkAllowed(.like))
    }

    func test_resetAll_clearsAllHistory() throws {
        let clock = MockClock()
        let configs: [RateLimitAction: RateLimitConfig] = [
            .like: RateLimitConfig(maxActions: 1, windowSeconds: 60, minIntervalSeconds: 0),
            .follow: RateLimitConfig(maxActions: 1, windowSeconds: 60, minIntervalSeconds: 0)
        ]
        let limiter = RateLimiter(configs: configs, clock: clock)

        try limiter.checkAllowed(.like)
        limiter.recordAction(.like)
        try limiter.checkAllowed(.follow)
        limiter.recordAction(.follow)

        XCTAssertThrowsError(try limiter.checkAllowed(.like))
        XCTAssertThrowsError(try limiter.checkAllowed(.follow))

        limiter.resetAll()

        XCTAssertNoThrow(try limiter.checkAllowed(.like))
        XCTAssertNoThrow(try limiter.checkAllowed(.follow))
    }

    func test_reset_doesNotAffectOtherActions() throws {
        let clock = MockClock()
        let configs: [RateLimitAction: RateLimitConfig] = [
            .like: RateLimitConfig(maxActions: 1, windowSeconds: 60, minIntervalSeconds: 0),
            .follow: RateLimitConfig(maxActions: 1, windowSeconds: 60, minIntervalSeconds: 0)
        ]
        let limiter = RateLimiter(configs: configs, clock: clock)

        try limiter.checkAllowed(.like)
        limiter.recordAction(.like)
        try limiter.checkAllowed(.follow)
        limiter.recordAction(.follow)

        limiter.reset(.like)

        XCTAssertNoThrow(try limiter.checkAllowed(.like))
        XCTAssertThrowsError(try limiter.checkAllowed(.follow))
    }

    // MARK: - Default Configs

    func test_defaultConfigs_coverAllActions() {
        let configs = RateLimiter.defaultConfigs

        XCTAssertNotNil(configs[.like])
        XCTAssertNotNil(configs[.comment])
        XCTAssertNotNil(configs[.follow])
        XCTAssertNotNil(configs[.unfollow])
        XCTAssertNotNil(configs[.search])
        XCTAssertNotNil(configs[.report])
        XCTAssertNotNil(configs[.deleteComment])
    }

    // MARK: - Sliding Window

    func test_slidingWindow_partialExpiry() throws {
        let clock = MockClock()
        let config = RateLimitConfig(maxActions: 2, windowSeconds: 10, minIntervalSeconds: 0)
        let limiter = RateLimiter(configs: [.like: config], clock: clock)

        // Record first action at t=0
        try limiter.checkAllowed(.like)
        limiter.recordAction(.like)

        // Record second action at t=5
        clock.advance(by: 5)
        try limiter.checkAllowed(.like)
        limiter.recordAction(.like)

        // At t=5, both actions in window — should be blocked
        XCTAssertThrowsError(try limiter.checkAllowed(.like))

        // At t=11, first action expired but second still in window
        clock.advance(by: 6)

        // Should have room for one more
        XCTAssertNoThrow(try limiter.checkAllowed(.like))
        limiter.recordAction(.like)

        // Now at capacity again
        XCTAssertThrowsError(try limiter.checkAllowed(.like))
    }

    // MARK: - Error Messages

    func test_throttledError_hasDescription() {
        let error = RateLimitError.throttled(action: .comment, retryAfter: 3.0)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_debouncedError_hasDescription() {
        let error = RateLimitError.debounced
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    // MARK: - RateLimitConfig Defaults

    func test_likeConfig_hasReasonableDefaults() {
        let config = RateLimitConfig.like
        XCTAssertEqual(config.maxActions, 30)
        XCTAssertEqual(config.windowSeconds, 60)
        XCTAssertGreaterThan(config.minIntervalSeconds, 0)
    }

    func test_commentConfig_hasReasonableDefaults() {
        let config = RateLimitConfig.comment
        XCTAssertEqual(config.maxActions, 12)
        XCTAssertEqual(config.windowSeconds, 60)
        XCTAssertEqual(config.minIntervalSeconds, 5)
    }

    func test_followConfig_hasReasonableDefaults() {
        let config = RateLimitConfig.follow
        XCTAssertEqual(config.maxActions, 10)
        XCTAssertEqual(config.windowSeconds, 60)
        XCTAssertGreaterThan(config.minIntervalSeconds, 0)
    }

    func test_reportConfig_hasReasonableDefaults() {
        let config = RateLimitConfig.report
        XCTAssertEqual(config.maxActions, 5)
        XCTAssertEqual(config.windowSeconds, 3600)
        XCTAssertGreaterThan(config.minIntervalSeconds, 0)
    }

    func test_deleteCommentConfig_hasReasonableDefaults() {
        let config = RateLimitConfig.deleteComment
        XCTAssertEqual(config.maxActions, 10)
        XCTAssertEqual(config.windowSeconds, 60)
        XCTAssertGreaterThan(config.minIntervalSeconds, 0)
    }
}
