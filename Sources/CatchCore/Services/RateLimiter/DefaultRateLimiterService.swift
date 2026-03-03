import Foundation

/// Thread-safe rate limiter that supports both debouncing and throttling.
///
/// - Debounce: If an action fires within `debounceInterval` of the last recorded
///   action of the same type, it is silently dropped (`.debounced`).
/// - Throttle: If the number of actions within a sliding `throttleWindow` exceeds
///   `maxActionsPerWindow`, the action is rejected (`.throttled`).
public final class DefaultRateLimiterService: RateLimiterService, @unchecked Sendable {
    private let configs: [RateLimitedAction: RateLimitConfig]
    private let lock = NSLock()
    private var timestamps: [RateLimitedAction: [Date]] = [:]
    private let now: () -> Date

    public init(
        configs: [RateLimitedAction: RateLimitConfig] = defaultConfigs(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.configs = configs
        self.now = now
    }

    public static func defaultConfigs() -> [RateLimitedAction: RateLimitConfig] {
        [
            .like: .like,
            .follow: .follow,
            .comment: .comment,
            .search: .search
        ]
    }

    public func checkAndRecord(action: RateLimitedAction) -> RateLimitResult {
        lock.lock()
        defer { lock.unlock() }

        guard let config = configs[action] else {
            return .allowed
        }

        let currentTime = now()
        var history = timestamps[action] ?? []

        // Prune entries older than the throttle window
        let windowStart = currentTime.addingTimeInterval(-config.throttleWindow)
        history = history.filter { $0 > windowStart }

        // Check debounce: is the most recent action too close?
        if let lastAction = history.last {
            let elapsed = currentTime.timeIntervalSince(lastAction)
            if elapsed < config.debounceInterval {
                timestamps[action] = history
                return .debounced
            }
        }

        // Check throttle: too many actions in the window?
        if history.count >= config.maxActionsPerWindow {
            let oldestInWindow = history.first ?? currentTime
            let retryAfter = config.throttleWindow - currentTime.timeIntervalSince(oldestInWindow)
            timestamps[action] = history
            return .throttled(retryAfter: max(0, retryAfter))
        }

        // Allowed — record the action
        history.append(currentTime)
        timestamps[action] = history
        return .allowed
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        timestamps = [:]
    }

    public func reset(action: RateLimitedAction) {
        lock.lock()
        defer { lock.unlock() }
        timestamps[action] = nil
    }
}
