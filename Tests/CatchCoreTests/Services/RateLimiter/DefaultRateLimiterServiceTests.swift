import XCTest
@testable import CatchCore

final class DefaultRateLimiterServiceTests: XCTestCase {

    // MARK: - Basic Allowed

    func test_firstAction_isAlwaysAllowed() {
        let limiter = DefaultRateLimiterService()

        let result = limiter.checkAndRecord(action: .like)

        XCTAssertEqual(result, .allowed)
    }

    func test_differentActions_areIndependent() {
        let limiter = DefaultRateLimiterService()

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)
        XCTAssertEqual(limiter.checkAndRecord(action: .comment), .allowed)
        XCTAssertEqual(limiter.checkAndRecord(action: .search), .allowed)
    }

    // MARK: - Debounce

    func test_rapidAction_isDebounced() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.like: RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 100, throttleWindow: 60)],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)

        // 0.5s later — within debounce interval
        currentTime = currentTime.addingTimeInterval(0.5)
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .debounced)
    }

    func test_actionAfterDebounceInterval_isAllowed() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.like: RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 100, throttleWindow: 60)],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)

        // 1.1s later — past debounce interval
        currentTime = currentTime.addingTimeInterval(1.1)
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
    }

    func test_debounce_doesNotAffectOtherActions() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [
                .like: RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 100, throttleWindow: 60),
                .follow: RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 100, throttleWindow: 60)
            ],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)

        // Immediate follow is fine — different action type
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)

        // But immediate like is debounced
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .debounced)

        // Advance past debounce
        currentTime = currentTime.addingTimeInterval(1.1)
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
    }

    // MARK: - Throttle

    func test_throttle_blocksAfterMaxActions() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.follow: RateLimitConfig(debounceInterval: 0, maxActionsPerWindow: 3, throttleWindow: 60)],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)
        currentTime = currentTime.addingTimeInterval(0.1)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)
        currentTime = currentTime.addingTimeInterval(0.1)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)

        // 4th action within window — throttled
        currentTime = currentTime.addingTimeInterval(0.1)
        let result = limiter.checkAndRecord(action: .follow)
        if case .throttled(let retryAfter) = result {
            XCTAssertGreaterThan(retryAfter, 0)
        } else {
            XCTFail("Expected throttled result, got \(result)")
        }
    }

    func test_throttle_allowsAfterWindowExpires() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.follow: RateLimitConfig(debounceInterval: 0, maxActionsPerWindow: 2, throttleWindow: 10)],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)
        currentTime = currentTime.addingTimeInterval(0.1)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)

        // Throttled
        currentTime = currentTime.addingTimeInterval(0.1)
        if case .throttled = limiter.checkAndRecord(action: .follow) {
            // expected
        } else {
            XCTFail("Expected throttled")
        }

        // Advance past window — oldest entry falls off
        currentTime = currentTime.addingTimeInterval(10.0)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)
    }

    func test_throttle_retryAfterIsReasonable() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.comment: RateLimitConfig(debounceInterval: 0, maxActionsPerWindow: 2, throttleWindow: 30)],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .comment), .allowed)
        currentTime = currentTime.addingTimeInterval(1.0)
        XCTAssertEqual(limiter.checkAndRecord(action: .comment), .allowed)

        // 3rd action at t=2
        currentTime = currentTime.addingTimeInterval(1.0)
        let result = limiter.checkAndRecord(action: .comment)
        if case .throttled(let retryAfter) = result {
            // Oldest action was at t=0, window is 30s, so retry after ~28s
            XCTAssertGreaterThan(retryAfter, 25)
            XCTAssertLessThanOrEqual(retryAfter, 30)
        } else {
            XCTFail("Expected throttled, got \(result)")
        }
    }

    // MARK: - Combined Debounce + Throttle

    func test_debounce_takePriorityOverThrottle() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.like: RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 100, throttleWindow: 60)],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)

        // Immediate second tap — debounced (not throttled, even though throttle limit hasn't been hit)
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .debounced)
    }

    // MARK: - Reset

    func test_reset_clearsAllActions() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.like: RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 100, throttleWindow: 60)],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .debounced)

        limiter.reset()

        // After reset, should be allowed immediately
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
    }

    func test_resetSpecificAction_onlyClearsThatAction() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [
                .like: RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 100, throttleWindow: 60),
                .follow: RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 100, throttleWindow: 60)
            ],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)

        // Both debounced
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .debounced)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .debounced)

        // Reset only like
        limiter.reset(action: .like)

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .debounced)
    }

    // MARK: - Unconfigured Action

    func test_unconfiguredAction_isAlwaysAllowed() {
        let limiter = DefaultRateLimiterService(configs: [:])

        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
        XCTAssertEqual(limiter.checkAndRecord(action: .like), .allowed)
        XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed)
    }

    // MARK: - Default Configs

    func test_defaultConfigs_coversAllActions() {
        let configs = DefaultRateLimiterService.defaultConfigs()

        XCTAssertNotNil(configs[.like])
        XCTAssertNotNil(configs[.follow])
        XCTAssertNotNil(configs[.comment])
        XCTAssertNotNil(configs[.search])
    }

    // MARK: - Comment Cooldown

    func test_commentCooldown_5secondDebounce() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.comment: .comment],
            now: { currentTime }
        )

        XCTAssertEqual(limiter.checkAndRecord(action: .comment), .allowed)

        // 3 seconds later — still within 5s debounce
        currentTime = currentTime.addingTimeInterval(3.0)
        XCTAssertEqual(limiter.checkAndRecord(action: .comment), .debounced)

        // 5.1 seconds after original — past debounce
        currentTime = currentTime.addingTimeInterval(2.1)
        XCTAssertEqual(limiter.checkAndRecord(action: .comment), .allowed)
    }

    // MARK: - Follow Limit

    func test_followLimit_10perMinute() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.follow: .follow],
            now: { currentTime }
        )

        // Fire 10 follows, each 1.1s apart (past 1s debounce)
        for i in 0..<10 {
            if i > 0 {
                currentTime = currentTime.addingTimeInterval(1.1)
            }
            XCTAssertEqual(limiter.checkAndRecord(action: .follow), .allowed, "Follow \(i) should be allowed")
        }

        // 11th follow — throttled
        currentTime = currentTime.addingTimeInterval(1.1)
        let result = limiter.checkAndRecord(action: .follow)
        if case .throttled = result {
            // expected
        } else {
            XCTFail("Expected 11th follow to be throttled, got \(result)")
        }
    }

    // MARK: - Sliding Window Pruning

    func test_slidingWindow_prunesOldEntries() {
        var currentTime = Date()
        let limiter = DefaultRateLimiterService(
            configs: [.search: RateLimitConfig(debounceInterval: 0, maxActionsPerWindow: 2, throttleWindow: 5)],
            now: { currentTime }
        )

        // Record 2 actions at t=0 and t=0.1
        XCTAssertEqual(limiter.checkAndRecord(action: .search), .allowed)
        currentTime = currentTime.addingTimeInterval(0.1)
        XCTAssertEqual(limiter.checkAndRecord(action: .search), .allowed)

        // t=0.2 — throttled
        currentTime = currentTime.addingTimeInterval(0.1)
        if case .throttled = limiter.checkAndRecord(action: .search) {
            // expected
        } else {
            XCTFail("Expected throttled")
        }

        // t=5.1 — first action (at t=0) has expired from window
        currentTime = currentTime.addingTimeInterval(5.0)
        XCTAssertEqual(limiter.checkAndRecord(action: .search), .allowed)
    }
}
