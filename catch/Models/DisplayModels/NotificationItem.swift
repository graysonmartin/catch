import Foundation
import CatchCore

struct NotificationItem: Identifiable, Equatable, Sendable {
    let id: String
    let notificationType: NotificationType
    let actorDisplayName: String
    let actorAvatarURL: String?
    let actorId: String?
    let encounterId: String?
    let encounterThumbnailURL: String?
    let timestamp: Date
    let isRead: Bool

    var actionDescription: String {
        switch notificationType {
        case .encounterLiked:
            return CatchStrings.Notifications.likedYourEncounter
        case .encounterCommented:
            return CatchStrings.Notifications.commentedOnYourEncounter
        case .newFollower:
            return CatchStrings.Notifications.startedFollowingYou
        }
    }

    /// Returns a copy with the `isRead` flag changed, avoiding manual field-by-field duplication.
    func withReadState(_ isRead: Bool) -> NotificationItem {
        NotificationItem(
            id: id,
            notificationType: notificationType,
            actorDisplayName: actorDisplayName,
            actorAvatarURL: actorAvatarURL,
            actorId: actorId,
            encounterId: encounterId,
            encounterThumbnailURL: encounterThumbnailURL,
            timestamp: timestamp,
            isRead: isRead
        )
    }
}
