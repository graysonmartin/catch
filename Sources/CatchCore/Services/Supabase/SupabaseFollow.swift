import Foundation

public struct SupabaseFollow: Codable {
    public let id: UUID
    public let followerID: UUID
    public let followeeID: UUID
    public let status: String
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case followerID = "follower_id"
        case followeeID = "followee_id"
        case status
        case createdAt = "created_at"
    }

    public func toDomain() -> Follow {
        Follow(
            id: id.uuidString,
            followerID: followerID.uuidString,
            followeeID: followeeID.uuidString,
            status: FollowStatus(rawValue: status) ?? .pending,
            createdAt: createdAt
        )
    }
}

/// Follow row with joined profile data from the `profiles` table.
public struct SupabaseFollowWithProfile: Codable {
    public let id: UUID
    public let followerID: UUID
    public let followeeID: UUID
    public let status: String
    public let createdAt: Date
    public let profiles: JoinedProfile?

    public init(
        id: UUID,
        followerID: UUID,
        followeeID: UUID,
        status: String,
        createdAt: Date,
        profiles: JoinedProfile?
    ) {
        self.id = id
        self.followerID = followerID
        self.followeeID = followeeID
        self.status = status
        self.createdAt = createdAt
        self.profiles = profiles
    }

    public struct JoinedProfile: Codable {
        public let displayName: String

        public init(displayName: String) {
            self.displayName = displayName
        }

        private enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case followerID = "follower_id"
        case followeeID = "followee_id"
        case status
        case createdAt = "created_at"
        case profiles
    }

    public func toDomain() -> Follow {
        Follow(
            id: id.uuidString,
            followerID: followerID.uuidString,
            followeeID: followeeID.uuidString,
            status: FollowStatus(rawValue: status) ?? .pending,
            createdAt: createdAt,
            followerDisplayName: profiles?.displayName
        )
    }
}

public struct SupabaseFollowInsertPayload: Codable {
    public let followerID: String
    public let followeeID: String
    public let status: String

    enum CodingKeys: String, CodingKey {
        case followerID = "follower_id"
        case followeeID = "followee_id"
        case status
    }
}

public struct SupabaseFollowUpdatePayload: Codable {
    public let status: String
}
