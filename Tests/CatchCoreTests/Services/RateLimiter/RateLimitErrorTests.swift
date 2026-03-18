import XCTest
@testable import CatchCore

final class RateLimitErrorTests: XCTestCase {

    func test_throttledError_isEquatable() {
        let error1 = RateLimitError.throttled(action: .like, retryAfter: 1.0)
        let error2 = RateLimitError.throttled(action: .like, retryAfter: 1.0)
        let error3 = RateLimitError.throttled(action: .comment, retryAfter: 1.0)

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func test_debouncedError_isEquatable() {
        XCTAssertEqual(RateLimitError.debounced, RateLimitError.debounced)
    }

    func test_throttledAndDebounced_areNotEqual() {
        let throttled = RateLimitError.throttled(action: .like, retryAfter: 1.0)
        let debounced = RateLimitError.debounced
        XCTAssertNotEqual(throttled, debounced)
    }

    func test_rateLimitAction_rawValues() {
        XCTAssertEqual(RateLimitAction.like.rawValue, "like")
        XCTAssertEqual(RateLimitAction.comment.rawValue, "comment")
        XCTAssertEqual(RateLimitAction.follow.rawValue, "follow")
        XCTAssertEqual(RateLimitAction.unfollow.rawValue, "unfollow")
        XCTAssertEqual(RateLimitAction.search.rawValue, "search")
    }

    func test_rateLimitConfig_equatable() {
        let config1 = RateLimitConfig(maxActions: 10, windowSeconds: 60, minIntervalSeconds: 1)
        let config2 = RateLimitConfig(maxActions: 10, windowSeconds: 60, minIntervalSeconds: 1)
        let config3 = RateLimitConfig(maxActions: 5, windowSeconds: 60, minIntervalSeconds: 1)

        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
    }
}
