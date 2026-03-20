import Foundation
import CatchCore

struct NotificationItem: Identifiable, Equatable, Sendable {
    let id: String
    let notificationType: NotificationType
    let actorDisplayName: String
    let actorAvatarURL: String?
    let encounterId: String
    let encounterThumbnailURL: String?
    let timestamp: Date
    let isRead: Bool

    var actionDescription: String {
        switch notificationType {
        case .encounterLiked:
            return CatchStrings.Notifications.likedYourEncounter
        case .encounterCommented:
            return CatchStrings.Notifications.commentedOnYourEncounter
        }
    }
}
