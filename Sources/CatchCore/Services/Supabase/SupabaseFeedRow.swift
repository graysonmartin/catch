import Foundation

/// A single feed row returned from a joined query across encounters, cats, and profiles.
/// Supabase PostgREST returns nested JSON for foreign-key joins.
public struct SupabaseFeedRow: Codable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public let catID: UUID
    public let date: Date
    public let locationName: String?
    public let locationLat: Double?
    public let locationLng: Double?
    public let notes: String?
    public let photoUrls: [String]
    public let likeCount: Int
    public let commentCount: Int
    public let createdAt: Date
    public let cat: SupabaseFeedCat
    public let owner: SupabaseFeedProfile

    public init(
        id: UUID,
        ownerID: UUID,
        catID: UUID,
        date: Date,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        notes: String?,
        photoUrls: [String],
        likeCount: Int,
        commentCount: Int,
        createdAt: Date,
        cat: SupabaseFeedCat,
        owner: SupabaseFeedProfile
    ) {
        self.id = id
        self.ownerID = ownerID
        self.catID = catID
        self.date = date
        self.locationName = locationName
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.notes = notes
        self.photoUrls = photoUrls
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.createdAt = createdAt
        self.cat = cat
        self.owner = owner
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case catID = "cat_id"
        case date
        case locationName = "location_name"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case notes
        case photoUrls = "photo_urls"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case cat = "cats"
        case owner = "profiles"
    }
}

/// Nested cat data from the feed join query.
public struct SupabaseFeedCat: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let breed: String?
    public let estimatedAge: String?
    public let locationName: String?
    public let locationLat: Double?
    public let locationLng: Double?
    public let notes: String?
    public let isOwned: Bool
    public let photoUrls: [String]
    public let createdAt: Date

    public init(
        id: UUID,
        name: String,
        breed: String?,
        estimatedAge: String?,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        notes: String?,
        isOwned: Bool,
        photoUrls: [String],
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.estimatedAge = estimatedAge
        self.locationName = locationName
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.notes = notes
        self.isOwned = isOwned
        self.photoUrls = photoUrls
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case breed
        case estimatedAge = "estimated_age"
        case locationName = "location_name"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case notes
        case isOwned = "is_owned"
        case photoUrls = "photo_urls"
        case createdAt = "created_at"
    }
}

/// Nested profile data from the feed join query.
public struct SupabaseFeedProfile: Codable, Sendable {
    public let id: UUID
    public let displayName: String
    public let username: String
    public let bio: String
    public let isPrivate: Bool
    public let avatarUrl: String?

    public init(
        id: UUID,
        displayName: String,
        username: String,
        bio: String,
        isPrivate: Bool,
        avatarUrl: String?
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.bio = bio
        self.isPrivate = isPrivate
        self.avatarUrl = avatarUrl
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case username
        case bio
        case isPrivate = "is_private"
        case avatarUrl = "avatar_url"
    }
}
