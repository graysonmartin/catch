import XCTest
@testable import CatchCore

final class RateLimitConfigTests: XCTestCase {

    // MARK: - Preset Configs

    func test_likeConfig_hasReasonableDefaults() {
        let config = RateLimitConfig.like

        XCTAssertEqual(config.debounceInterval, 0.5)
        XCTAssertEqual(config.maxActionsPerWindow, 30)
        XCTAssertEqual(config.throttleWindow, 60)
    }

    func test_followConfig_hasReasonableDefaults() {
        let config = RateLimitConfig.follow

        XCTAssertEqual(config.debounceInterval, 1.0)
        XCTAssertEqual(config.maxActionsPerWindow, 10)
        XCTAssertEqual(config.throttleWindow, 60)
    }

    func test_commentConfig_has5secondCooldown() {
        let config = RateLimitConfig.comment

        XCTAssertEqual(config.debounceInterval, 5.0)
        XCTAssertEqual(config.maxActionsPerWindow, 10)
        XCTAssertEqual(config.throttleWindow, 60)
    }

    func test_searchConfig_hasReasonableDefaults() {
        let config = RateLimitConfig.search

        XCTAssertEqual(config.debounceInterval, 0.5)
        XCTAssertEqual(config.maxActionsPerWindow, 20)
        XCTAssertEqual(config.throttleWindow, 60)
    }

    // MARK: - Equatable

    func test_configs_areEquatable() {
        let a = RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 10, throttleWindow: 60)
        let b = RateLimitConfig(debounceInterval: 1.0, maxActionsPerWindow: 10, throttleWindow: 60)
        let c = RateLimitConfig(debounceInterval: 2.0, maxActionsPerWindow: 10, throttleWindow: 60)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - Custom Init

    func test_customConfig_storesValues() {
        let config = RateLimitConfig(
            debounceInterval: 3.5,
            maxActionsPerWindow: 42,
            throttleWindow: 120
        )

        XCTAssertEqual(config.debounceInterval, 3.5)
        XCTAssertEqual(config.maxActionsPerWindow, 42)
        XCTAssertEqual(config.throttleWindow, 120)
    }

    // MARK: - RateLimitedAction

    func test_rateLimitedAction_rawValues() {
        XCTAssertEqual(RateLimitedAction.like.rawValue, "like")
        XCTAssertEqual(RateLimitedAction.follow.rawValue, "follow")
        XCTAssertEqual(RateLimitedAction.comment.rawValue, "comment")
        XCTAssertEqual(RateLimitedAction.search.rawValue, "search")
    }

    // MARK: - RateLimitResult

    func test_rateLimitResult_equatable() {
        XCTAssertEqual(RateLimitResult.allowed, .allowed)
        XCTAssertEqual(RateLimitResult.debounced, .debounced)
        XCTAssertEqual(RateLimitResult.throttled(retryAfter: 5), .throttled(retryAfter: 5))
        XCTAssertNotEqual(RateLimitResult.allowed, .debounced)
        XCTAssertNotEqual(RateLimitResult.throttled(retryAfter: 5), .throttled(retryAfter: 10))
    }
}
