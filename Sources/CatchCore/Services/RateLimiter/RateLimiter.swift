import Foundation

/// Client-side rate limiter that enforces debounce and throttle limits
/// per action type using a sliding time window.
public final class RateLimiter: RateLimiting, @unchecked Sendable {
    private let configs: [RateLimitAction: RateLimitConfig]
    private let lock = NSLock()
    private let clock: any RateLimiterClock

    /// Timestamps of recent actions, keyed by action type.
    private var actionHistory: [RateLimitAction: [Date]] = [:]

    public init(
        configs: [RateLimitAction: RateLimitConfig] = RateLimiter.defaultConfigs,
        clock: any RateLimiterClock = SystemClock()
    ) {
        self.configs = configs
        self.clock = clock
    }

    /// Default rate limit configurations for all action types.
    public static let defaultConfigs: [RateLimitAction: RateLimitConfig] = [
        .like: .like,
        .comment: .comment,
        .follow: .follow,
        .unfollow: .unfollow,
        .search: .search
    ]

    // MARK: - RateLimiting

    public func checkAllowed(_ action: RateLimitAction) throws {
        guard let config = configs[action] else { return }

        lock.lock()
        defer { lock.unlock() }

        let now = clock.now()
        pruneExpiredEntries(for: action, before: now, window: config.windowSeconds)

        let history = actionHistory[action] ?? []

        // Check debounce — minimum interval between actions
        if config.minIntervalSeconds > 0, let lastAction = history.last {
            let elapsed = now.timeIntervalSince(lastAction)
            if elapsed < config.minIntervalSeconds {
                let retryAfter = config.minIntervalSeconds - elapsed
                throw RateLimitError.throttled(action: action, retryAfter: retryAfter)
            }
        }

        // Check throttle — max actions per window
        if history.count >= config.maxActions {
            let oldestInWindow = history[0]
            let retryAfter = config.windowSeconds - now.timeIntervalSince(oldestInWindow)
            throw RateLimitError.throttled(action: action, retryAfter: max(0.1, retryAfter))
        }
    }

    public func recordAction(_ action: RateLimitAction) {
        lock.lock()
        defer { lock.unlock() }

        let now = clock.now()
        actionHistory[action, default: []].append(now)
    }

    public func reset(_ action: RateLimitAction) {
        lock.lock()
        defer { lock.unlock() }

        actionHistory.removeValue(forKey: action)
    }

    public func resetAll() {
        lock.lock()
        defer { lock.unlock() }

        actionHistory.removeAll()
    }

    // MARK: - Private

    private func pruneExpiredEntries(
        for action: RateLimitAction,
        before now: Date,
        window: TimeInterval
    ) {
        guard var history = actionHistory[action] else { return }

        let cutoff = now.addingTimeInterval(-window)
        history.removeAll { $0 < cutoff }
        actionHistory[action] = history
    }
}
