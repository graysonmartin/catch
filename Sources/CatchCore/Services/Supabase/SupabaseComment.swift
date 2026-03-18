import Foundation

/// Row returned from the `encounter_comments` table.
public struct SupabaseComment: Codable, Sendable {
    public let id: UUID
    public let encounterID: UUID
    public let userID: UUID
    public let text: String
    public let createdAt: Date

    public init(id: UUID, encounterID: UUID, userID: UUID, text: String, createdAt: Date) {
        self.id = id
        self.encounterID = encounterID
        self.userID = userID
        self.text = text
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case encounterID = "encounter_id"
        case userID = "user_id"
        case text
        case createdAt = "created_at"
    }

    public func toDomain() -> EncounterComment {
        EncounterComment(
            id: id.uuidString.lowercased(),
            encounterRecordName: encounterID.uuidString.lowercased(),
            userID: userID.uuidString.lowercased(),
            text: text,
            createdAt: createdAt
        )
    }
}

/// Comment row with joined profile data for display names.
public struct SupabaseCommentWithProfile: Codable, Sendable {
    public let id: UUID
    public let encounterID: UUID
    public let userID: UUID
    public let text: String
    public let createdAt: Date
    public let profiles: JoinedProfile?

    public init(
        id: UUID,
        encounterID: UUID,
        userID: UUID,
        text: String,
        createdAt: Date,
        profiles: JoinedProfile?
    ) {
        self.id = id
        self.encounterID = encounterID
        self.userID = userID
        self.text = text
        self.createdAt = createdAt
        self.profiles = profiles
    }

    public struct JoinedProfile: Codable, Sendable {
        public let displayName: String
        public let avatarURL: String?

        public init(displayName: String, avatarURL: String? = nil) {
            self.displayName = displayName
            self.avatarURL = avatarURL
        }

        private enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case avatarURL = "avatar_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case encounterID = "encounter_id"
        case userID = "user_id"
        case text
        case createdAt = "created_at"
        case profiles
    }

    public func toDomain() -> EncounterComment {
        EncounterComment(
            id: id.uuidString.lowercased(),
            encounterRecordName: encounterID.uuidString.lowercased(),
            userID: userID.uuidString.lowercased(),
            displayName: profiles?.displayName,
            avatarURL: profiles?.avatarURL,
            text: text,
            createdAt: createdAt
        )
    }
}

/// Payload for inserting a comment row.
struct SupabaseCommentInsertPayload: Codable {
    let encounterID: String
    let userID: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case encounterID = "encounter_id"
        case userID = "user_id"
        case text
    }
}

/// Lightweight row for count queries on the encounters table.
public struct SupabaseEncounterCounts: Codable, Sendable {
    public let id: UUID
    public let likeCount: Int
    public let commentCount: Int

    public init(id: UUID, likeCount: Int, commentCount: Int) {
        self.id = id
        self.likeCount = likeCount
        self.commentCount = commentCount
    }

    enum CodingKeys: String, CodingKey {
        case id
        case likeCount = "like_count"
        case commentCount = "comment_count"
    }
}
