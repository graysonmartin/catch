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
    /// The encounter join uses the dedicated `encounter_id` FK column (nullable).
    /// Follow notifications have `encounter_id = NULL` so the join returns null gracefully.
    private static let selectQuery = """
        id, notification_type, entity_id, actor_id, read_at, created_at, \
        profiles!notifications_actor_profile_fkey(display_name, avatar_url), \
        encounters!notifications_encounter_id_fkey(photo_urls)
        """

    private static let readAtFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

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
        notifications[index] = original.withReadState(true)
        unreadCount = notifications.filter { !$0.isRead }.count

        do {
            try await clientProvider.client
                .from(Self.tableName)
                .update(["read_at": Self.readAtFormatter.string(from: Date())])
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
        notifications = notifications.map { $0.isRead ? $0 : $0.withReadState(true) }
        unreadCount = 0

        do {
            try await clientProvider.client
                .from(Self.tableName)
                .update(["read_at": Self.readAtFormatter.string(from: Date())])
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

        let encounterId: String?
        let encounterThumbnailURL: String?

        switch type {
        case .encounterLiked, .encounterCommented:
            encounterId = row.entityId
            encounterThumbnailURL = row.encounter?.photoURLs?.first
        case .newFollower:
            encounterId = nil
            encounterThumbnailURL = nil
        }

        return NotificationItem(
            id: row.id,
            notificationType: type,
            actorDisplayName: row.actor?.displayName ?? CatchStrings.Notifications.unknownUser,
            actorAvatarURL: row.actor?.avatarURL,
            actorId: row.actorId,
            encounterId: encounterId,
            encounterThumbnailURL: encounterThumbnailURL,
            timestamp: row.createdAt,
            isRead: row.readAt != nil
        )
    }
}
