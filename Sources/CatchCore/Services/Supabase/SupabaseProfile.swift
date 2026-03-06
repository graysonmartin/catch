import Foundation

public struct SupabaseProfile: Codable, Sendable {
    public let id: UUID
    public let displayName: String
    public let username: String
    public let bio: String
    public let isPrivate: Bool
    public let showCats: Bool
    public let showEncounters: Bool
    public let avatarUrl: String?
    public let followerCount: Int
    public let followingCount: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID,
        displayName: String,
        username: String,
        bio: String,
        isPrivate: Bool,
        showCats: Bool,
        showEncounters: Bool,
        avatarUrl: String?,
        followerCount: Int,
        followingCount: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.bio = bio
        self.isPrivate = isPrivate
        self.showCats = showCats
        self.showEncounters = showEncounters
        self.avatarUrl = avatarUrl
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case username
        case bio
        case isPrivate = "is_private"
        case showCats = "show_cats"
        case showEncounters = "show_encounters"
        case avatarUrl = "avatar_url"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
