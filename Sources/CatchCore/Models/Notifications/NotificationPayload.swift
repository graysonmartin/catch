import Foundation

public struct NotificationPayload: Codable, Sendable, Equatable {
    public let notificationType: NotificationType
    public let entityType: String
    public let entityId: String
    public let actorId: String?
    public let collapseKey: String?
    public let createdAt: Date
    public let version: Int

    public init(
        notificationType: NotificationType,
        entityType: String,
        entityId: String,
        actorId: String? = nil,
        collapseKey: String? = nil,
        createdAt: Date,
        version: Int = 1
    ) {
        self.notificationType = notificationType
        self.entityType = entityType
        self.entityId = entityId
        self.actorId = actorId
        self.collapseKey = collapseKey
        self.createdAt = createdAt
        self.version = version
    }

    private enum CodingKeys: String, CodingKey {
        case notificationType = "notification_type"
        case entityType = "entity_type"
        case entityId = "entity_id"
        case actorId = "actor_id"
        case collapseKey = "collapse_key"
        case createdAt = "created_at"
        case version
    }
}
