import Foundation

/// Error thrown when a social action is rate-limited.
public enum RateLimitError: LocalizedError, Equatable {
    case throttled(action: RateLimitAction, retryAfter: TimeInterval)
    case debounced

    public var errorDescription: String? {
        switch self {
        case .throttled:
            "slow down there"
        case .debounced:
            "hold on, still processing"
        }
    }
}
