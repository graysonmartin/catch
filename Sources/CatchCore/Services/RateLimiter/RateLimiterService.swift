import Foundation

/// Defines the types of social actions that can be rate-limited.
public enum RateLimitedAction: String, Sendable {
    case like
    case follow
    case comment
    case search
}

/// Result of a rate limit check.
public enum RateLimitResult: Sendable, Equatable {
    /// Action is allowed to proceed.
    case allowed
    /// Action was debounced — a duplicate rapid tap, silently ignored.
    case debounced
    /// Action was throttled — too many in the time window.
    case throttled(retryAfter: TimeInterval)
}

/// Protocol for checking and recording rate-limited actions.
public protocol RateLimiterService: Sendable {
    /// Check whether an action is allowed, and record it if so.
    func checkAndRecord(action: RateLimitedAction) -> RateLimitResult

    /// Reset all recorded actions (useful for testing or sign-out).
    func reset()

    /// Reset recorded actions for a specific action type.
    func reset(action: RateLimitedAction)
}
