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
