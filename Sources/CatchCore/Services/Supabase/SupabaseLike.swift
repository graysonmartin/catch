import Foundation

/// Row returned from the `encounter_likes` table.
public struct SupabaseLike: Codable, Sendable {
    public let id: UUID
    public let encounterID: UUID
    public let userID: UUID
    public let createdAt: Date

    public init(id: UUID, encounterID: UUID, userID: UUID, createdAt: Date) {
        self.id = id
        self.encounterID = encounterID
        self.userID = userID
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case encounterID = "encounter_id"
        case userID = "user_id"
        case createdAt = "created_at"
    }

    public func toDomain() -> EncounterLike {
        EncounterLike(
            id: id.uuidString,
            encounterRecordName: encounterID.uuidString,
            userID: userID.uuidString,
            createdAt: createdAt
        )
    }
}

/// Like row with joined profile data for the "liked by" list.
public struct SupabaseLikeWithProfile: Codable, Sendable {
    public let id: UUID
    public let encounterID: UUID
    public let userID: UUID
    public let createdAt: Date
    public let profiles: JoinedProfile?

    public init(
        id: UUID,
        encounterID: UUID,
        userID: UUID,
        createdAt: Date,
        profiles: JoinedProfile?
    ) {
        self.id = id
        self.encounterID = encounterID
        self.userID = userID
        self.createdAt = createdAt
        self.profiles = profiles
    }

    public struct JoinedProfile: Codable, Sendable {
        public let displayName: String
        public let username: String?

        public init(displayName: String, username: String?) {
            self.displayName = displayName
            self.username = username
        }

        private enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case username
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case encounterID = "encounter_id"
        case userID = "user_id"
        case createdAt = "created_at"
        case profiles
    }

    public func toLikedByUser() -> LikedByUser {
        LikedByUser(
            id: id.uuidString,
            userID: userID.uuidString,
            displayName: profiles?.displayName ?? String(userID.uuidString.prefix(8)),
            username: profiles?.username,
            likedAt: createdAt
        )
    }
}

/// Payload for inserting a like row.
struct SupabaseLikeInsertPayload: Codable {
    let encounterID: String
    let userID: String

    enum CodingKeys: String, CodingKey {
        case encounterID = "encounter_id"
        case userID = "user_id"
    }
}
