import Foundation

/// Configuration for rate limiting a specific action type.
public struct RateLimitConfig: Sendable, Equatable {
    /// Minimum interval between individual actions (debounce).
    /// Actions within this window are silently dropped.
    public let debounceInterval: TimeInterval

    /// Maximum number of actions allowed within `throttleWindow`.
    public let maxActionsPerWindow: Int

    /// The sliding time window for throttle counting.
    public let throttleWindow: TimeInterval

    public init(
        debounceInterval: TimeInterval,
        maxActionsPerWindow: Int,
        throttleWindow: TimeInterval
    ) {
        self.debounceInterval = debounceInterval
        self.maxActionsPerWindow = maxActionsPerWindow
        self.throttleWindow = throttleWindow
    }

    // MARK: - Defaults

    /// Like: 0.5s debounce, 30 per minute.
    public static let like = RateLimitConfig(
        debounceInterval: 0.5,
        maxActionsPerWindow: 30,
        throttleWindow: 60
    )

    /// Follow: 1s debounce, 10 per minute.
    public static let follow = RateLimitConfig(
        debounceInterval: 1.0,
        maxActionsPerWindow: 10,
        throttleWindow: 60
    )

    /// Comment: 5s debounce (cooldown), 10 per minute.
    public static let comment = RateLimitConfig(
        debounceInterval: 5.0,
        maxActionsPerWindow: 10,
        throttleWindow: 60
    )

    /// Search: 0.5s debounce, 20 per minute.
    public static let search = RateLimitConfig(
        debounceInterval: 0.5,
        maxActionsPerWindow: 20,
        throttleWindow: 60
    )
}
