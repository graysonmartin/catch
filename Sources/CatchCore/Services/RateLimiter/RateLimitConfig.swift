import Foundation

/// Configuration for rate limiting a specific action type.
public struct RateLimitConfig: Sendable, Equatable {
    /// Maximum number of actions allowed within the time window.
    public let maxActions: Int

    /// Duration of the sliding time window in seconds.
    public let windowSeconds: TimeInterval

    /// Minimum interval between individual actions (debounce).
    /// Set to 0 to disable debounce for this action.
    public let minIntervalSeconds: TimeInterval

    public init(
        maxActions: Int,
        windowSeconds: TimeInterval,
        minIntervalSeconds: TimeInterval = 0
    ) {
        self.maxActions = maxActions
        self.windowSeconds = windowSeconds
        self.minIntervalSeconds = minIntervalSeconds
    }
}

// MARK: - Default Configurations

extension RateLimitConfig {
    /// Like: debounce rapid taps, allow 30 per minute.
    public static let like = RateLimitConfig(
        maxActions: 30,
        windowSeconds: 60,
        minIntervalSeconds: 0.5
    )

    /// Comment: throttle to 1 per 5 seconds, max 12 per minute.
    public static let comment = RateLimitConfig(
        maxActions: 12,
        windowSeconds: 60,
        minIntervalSeconds: 5
    )

    /// Follow/unfollow: max 10 per minute with 1s debounce.
    public static let follow = RateLimitConfig(
        maxActions: 10,
        windowSeconds: 60,
        minIntervalSeconds: 1
    )

    /// Unfollow: same limits as follow.
    public static let unfollow = RateLimitConfig(
        maxActions: 10,
        windowSeconds: 60,
        minIntervalSeconds: 1
    )

    /// Search: debounce rapid queries, allow 20 per minute.
    public static let search = RateLimitConfig(
        maxActions: 20,
        windowSeconds: 60,
        minIntervalSeconds: 0.3
    )

    /// Report: max 5 per hour with 3s debounce to prevent spam.
    public static let report = RateLimitConfig(
        maxActions: 5,
        windowSeconds: 3600,
        minIntervalSeconds: 3
    )

    /// Delete comment: max 10 per minute with 1s debounce.
    public static let deleteComment = RateLimitConfig(
        maxActions: 10,
        windowSeconds: 60,
        minIntervalSeconds: 1
    )
}
