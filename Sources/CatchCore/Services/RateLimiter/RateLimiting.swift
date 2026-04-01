import Foundation

/// Protocol for rate limiting social actions with debounce and throttle support.
public protocol RateLimiting: Sendable {
    /// Checks whether an action is allowed. Returns normally if allowed,
    /// throws `RateLimitError` if the action should be blocked.
    func checkAllowed(_ action: RateLimitAction) throws

    /// Records that an action was performed. Call after the action succeeds.
    func recordAction(_ action: RateLimitAction)

    /// Resets all tracked state for a given action.
    func reset(_ action: RateLimitAction)

    /// Resets all tracked state for all actions.
    func resetAll()
}
