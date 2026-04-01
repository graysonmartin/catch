import Foundation

/// Defines the types of social actions that can be rate-limited.
public enum RateLimitAction: String, Sendable, Hashable {
    case like
    case comment
    case follow
    case unfollow
    case search
    case report
    case deleteComment
}
