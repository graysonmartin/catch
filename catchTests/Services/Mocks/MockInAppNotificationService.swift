import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockInAppNotificationService: InAppNotificationService, @unchecked Sendable {
    var notifications: [NotificationItem] = []
    var unreadCount: Int = 0
    var isLoading: Bool = false
    var hasLoaded: Bool = false

    private(set) var loadIfNeededCalls = 0
    private(set) var refreshCalls = 0
    private(set) var markAsReadCalls: [String] = []
    private(set) var markAllAsReadCalls = 0

    var refreshHandler: (() async -> Void)?

    func loadIfNeeded() async {
        loadIfNeededCalls += 1
        hasLoaded = true
    }

    func refresh() async {
        refreshCalls += 1
        await refreshHandler?()
    }

    func markAsRead(notificationId: String) async {
        markAsReadCalls.append(notificationId)
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            let item = notifications[index]
            notifications[index] = NotificationItem(
                id: item.id,
                notificationType: item.notificationType,
                actorDisplayName: item.actorDisplayName,
                actorAvatarURL: item.actorAvatarURL,
                encounterId: item.encounterId,
                encounterThumbnailURL: item.encounterThumbnailURL,
                timestamp: item.timestamp,
                isRead: true
            )
            unreadCount = notifications.filter { !$0.isRead }.count
        }
    }

    func markAllAsRead() async {
        markAllAsReadCalls += 1
        notifications = notifications.map { item in
            NotificationItem(
                id: item.id,
                notificationType: item.notificationType,
                actorDisplayName: item.actorDisplayName,
                actorAvatarURL: item.actorAvatarURL,
                encounterId: item.encounterId,
                encounterThumbnailURL: item.encounterThumbnailURL,
                timestamp: item.timestamp,
                isRead: true
            )
        }
        unreadCount = 0
    }

    func reset() {
        notifications = []
        unreadCount = 0
        isLoading = false
        hasLoaded = false
        loadIfNeededCalls = 0
        refreshCalls = 0
        markAsReadCalls = []
        markAllAsReadCalls = 0
        refreshHandler = nil
    }
}
