import Foundation

/// Row returned from the `encounters` table.
public struct SupabaseEncounter: Codable, Sendable {
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
    public let updatedAt: Date

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
        updatedAt: Date
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
        self.updatedAt = updatedAt
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
        case updatedAt = "updated_at"
    }
}

/// Payload for inserting an encounter row with a client-supplied ID.
public struct SupabaseEncounterInsertPayload: Codable, Sendable {
    public let id: String
    public let ownerID: String
    public let catID: String
    public let date: Date
    public let locationName: String?
    public let locationLat: Double?
    public let locationLng: Double?
    public let notes: String?
    public let photoUrls: [String]

    public init(
        id: String,
        ownerID: String,
        catID: String,
        date: Date,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        notes: String?,
        photoUrls: [String]
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
    }
}

/// Payload for updating mutable encounter fields.
public struct SupabaseEncounterUpdatePayload: Codable, Sendable {
    public let date: Date
    public let locationName: String?
    public let locationLat: Double?
    public let locationLng: Double?
    public let notes: String?
    public let photoUrls: [String]

    public init(
        date: Date,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        notes: String?,
        photoUrls: [String]
    ) {
        self.date = date
        self.locationName = locationName
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.notes = notes
        self.photoUrls = photoUrls
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case locationName = "location_name"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case notes
        case photoUrls = "photo_urls"
    }
}
