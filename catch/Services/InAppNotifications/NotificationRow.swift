import Foundation

/// Decodable row returned by the Supabase `notifications` query with joined profile and encounter data.
struct NotificationRow: Decodable, Sendable {
    let id: String
    let notificationType: String
    let entityId: String
    let actorId: String?
    let readAt: Date?
    let createdAt: Date
    let actor: ActorProfile?
    let encounter: EncounterThumbnail?

    struct ActorProfile: Decodable, Sendable {
        let displayName: String?
        let avatarURL: String?

        private enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case avatarURL = "avatar_url"
        }
    }

    struct EncounterThumbnail: Decodable, Sendable {
        let photoURLs: [String]?

        private enum CodingKeys: String, CodingKey {
            case photoURLs = "photo_urls"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case notificationType = "notification_type"
        case entityId = "entity_id"
        case actorId = "actor_id"
        case readAt = "read_at"
        case createdAt = "created_at"
        case actor = "profiles"
        case encounter = "encounters"
    }
}
