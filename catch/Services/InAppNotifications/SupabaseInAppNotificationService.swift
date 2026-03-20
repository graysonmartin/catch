import Foundation
import Observation
import CatchCore
import Supabase

@Observable
@MainActor
final class SupabaseInAppNotificationService: InAppNotificationService, @unchecked Sendable {

    // MARK: - Published State

    private(set) var notifications: [NotificationItem] = []
    private(set) var unreadCount: Int = 0
    private(set) var isLoading = false
    private(set) var hasLoaded = false

    // MARK: - Dependencies

    private let clientProvider: any SupabaseClientProviding
    private let getCurrentUserID: @Sendable () -> String?

    private static let tableName = "notifications"
    private static let pageSize = PaginationConstants.defaultPageSize

    /// Supabase select query joining actor profile and encounter thumbnail.
    /// `profiles` is joined via `actor_id` to get the actor's display name and avatar.
    /// `encounters` is joined via `entity_id` to get the encounter's first photo URL.
    private static let selectQuery = """
        id, notification_type, entity_id, actor_id, read_at, created_at, \
        profiles!notifications_actor_profile_fkey(display_name, avatar_url), \
        encounters!notifications_encounter_fkey(photo_urls)
        """

    // MARK: - Init

    init(
        clientProvider: any SupabaseClientProviding,
        getCurrentUserID: @escaping @Sendable () -> String?
    ) {
        self.clientProvider = clientProvider
        self.getCurrentUserID = getCurrentUserID
    }

    // MARK: - InAppNotificationService

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard let userID = getCurrentUserID() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let rows: [NotificationRow] = try await clientProvider.client
                .from(Self.tableName)
                .select(Self.selectQuery)
                .eq("recipient_user_id", value: userID)
                .order("created_at", ascending: false)
                .limit(Self.pageSize)
                .execute()
                .value

            notifications = rows.compactMap(mapRow)
            unreadCount = notifications.filter { !$0.isRead }.count
            hasLoaded = true
        } catch {
            // Keep existing state on refresh failure
            if !hasLoaded {
                notifications = []
                unreadCount = 0
            }
        }
    }

    func markAsRead(notificationId: String) async {
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }),
              !notifications[index].isRead else {
            return
        }

        // Optimistic update
        let original = notifications[index]
        notifications[index] = NotificationItem(
            id: original.id,
            notificationType: original.notificationType,
            actorDisplayName: original.actorDisplayName,
            actorAvatarURL: original.actorAvatarURL,
            encounterId: original.encounterId,
            encounterThumbnailURL: original.encounterThumbnailURL,
            timestamp: original.timestamp,
            isRead: true
        )
        unreadCount = notifications.filter { !$0.isRead }.count

        do {
            try await clientProvider.client
                .from(Self.tableName)
                .update(["read_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: notificationId)
                .execute()
        } catch {
            // Revert on failure
            notifications[index] = original
            unreadCount = notifications.filter { !$0.isRead }.count
        }
    }

    func markAllAsRead() async {
        guard let userID = getCurrentUserID() else { return }

        let unreadIDs = notifications.filter { !$0.isRead }.map(\.id)
        guard !unreadIDs.isEmpty else { return }

        // Optimistic update
        let originals = notifications
        notifications = notifications.map { item in
            guard !item.isRead else { return item }
            return NotificationItem(
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

        do {
            try await clientProvider.client
                .from(Self.tableName)
                .update(["read_at": ISO8601DateFormatter().string(from: Date())])
                .eq("recipient_user_id", value: userID)
                .is("read_at", value: nil)
                .execute()
        } catch {
            // Revert on failure
            notifications = originals
            unreadCount = originals.filter { !$0.isRead }.count
        }
    }

    // MARK: - Mapping

    private func mapRow(_ row: NotificationRow) -> NotificationItem? {
        guard let type = NotificationType(rawValue: row.notificationType) else {
            return nil
        }

        return NotificationItem(
            id: row.id,
            notificationType: type,
            actorDisplayName: row.actor?.displayName ?? CatchStrings.Notifications.unknownUser,
            actorAvatarURL: row.actor?.avatarURL,
            encounterId: row.entityId,
            encounterThumbnailURL: row.encounter?.photoURLs?.first,
            timestamp: row.createdAt,
            isRead: row.readAt != nil
        )
    }
}
