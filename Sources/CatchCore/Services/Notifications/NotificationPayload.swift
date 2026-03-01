import Foundation

public enum NotificationEventType: String, Sendable, Equatable {
    case newEncounter = "new_encounter"
    case encounterLiked = "encounter_liked"
    case encounterCommented = "encounter_commented"
}

public struct NotificationPayload: Sendable, Equatable {
    public let eventType: NotificationEventType
    public let subscriptionID: String

    public init(eventType: NotificationEventType, subscriptionID: String) {
        self.eventType = eventType
        self.subscriptionID = subscriptionID
    }

    // MARK: - Subscription ID conventions

    public static let encounterSubscriptionPrefix = "new-encounter-"
    public static let likeSubscriptionPrefix = "encounter-liked-"
    public static let commentSubscriptionPrefix = "encounter-commented-"

    public static func encounterSubscriptionID(for ownerID: String) -> String {
        "\(encounterSubscriptionPrefix)\(ownerID)"
    }

    public static func likeSubscriptionID(for ownerID: String) -> String {
        "\(likeSubscriptionPrefix)\(ownerID)"
    }

    public static func commentSubscriptionID(for ownerID: String) -> String {
        "\(commentSubscriptionPrefix)\(ownerID)"
    }

    public static func eventType(for subscriptionID: String) -> NotificationEventType? {
        if subscriptionID.hasPrefix(encounterSubscriptionPrefix) {
            return .newEncounter
        } else if subscriptionID.hasPrefix(likeSubscriptionPrefix) {
            return .encounterLiked
        } else if subscriptionID.hasPrefix(commentSubscriptionPrefix) {
            return .encounterCommented
        }
        return nil
    }
}
