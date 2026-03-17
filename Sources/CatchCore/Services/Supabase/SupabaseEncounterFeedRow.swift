import Foundation

/// A single row returned from a paginated encounter feed query with joined cat data.
/// Used for the local user's feed — encounters ordered by date with their associated cat.
public struct SupabaseEncounterFeedRow: Codable, Sendable {
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
        cat: SupabaseFeedCat
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
    }
}
