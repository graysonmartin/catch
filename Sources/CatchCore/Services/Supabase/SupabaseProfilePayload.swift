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

/// Insert payload that adds the user's auth ID to the profile fields.
struct SupabaseProfileInsertPayload: Codable {
    let id: String
    let displayName: String
    let username: String
    let bio: String
    let isPrivate: Bool
    let showCats: Bool
    let showEncounters: Bool
    let avatarUrl: String?

    init(id: String, profile: SupabaseProfilePayload) {
        self.id = id
        self.displayName = profile.displayName
        self.username = profile.username
        self.bio = profile.bio
        self.isPrivate = profile.isPrivate
        self.showCats = profile.showCats
        self.showEncounters = profile.showEncounters
        self.avatarUrl = profile.avatarUrl
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
    }
}
