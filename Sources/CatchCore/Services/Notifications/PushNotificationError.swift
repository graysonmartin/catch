import Foundation

public enum PushNotificationError: LocalizedError, Equatable {
    case authorizationDenied
    case subscriptionFailed
    case notSignedIn
    case fetchSubscriptionsFailed

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            "notification permissions denied — enable in settings"
        case .subscriptionFailed:
            "couldn't set up push notifications"
        case .notSignedIn:
            "sign in to get notified about your cats"
        case .fetchSubscriptionsFailed:
            "couldn't check existing notification subscriptions"
        }
    }
}
