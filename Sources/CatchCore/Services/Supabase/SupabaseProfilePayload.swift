import Foundation

public struct SupabaseProfilePayload: Codable, Sendable {
    public let displayName: String
    public let username: String
    public let bio: String
    public let isPrivate: Bool
    public let showCats: Bool
    public let showEncounters: Bool
    public let avatarUrl: String?

    public init(
        displayName: String,
        username: String,
        bio: String,
        isPrivate: Bool,
        showCats: Bool = true,
        showEncounters: Bool = true,
        avatarUrl: String? = nil
    ) {
        self.displayName = displayName
        self.username = username
        self.bio = bio
        self.isPrivate = isPrivate
        self.showCats = showCats
        self.showEncounters = showEncounters
        self.avatarUrl = avatarUrl
    }

    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case username
        case bio
        case isPrivate = "is_private"
        case showCats = "show_cats"
        case showEncounters = "show_encounters"
        case avatarUrl = "avatar_url"
    }
}
