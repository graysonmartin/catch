import Foundation

/// Row returned from the `cats` table.
public struct SupabaseCat: Codable, Sendable {
    public let id: UUID
    public let ownerID: UUID
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
    public let updatedAt: Date

    public init(
        id: UUID,
        ownerID: UUID,
        name: String,
        breed: String?,
        estimatedAge: String?,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        notes: String?,
        isOwned: Bool,
        photoUrls: [String],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.ownerID = ownerID
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
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
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
        case updatedAt = "updated_at"
    }
}

/// Payload for inserting a cat row with a client-supplied ID.
public struct SupabaseCatInsertPayload: Codable, Sendable {
    public let id: String
    public let ownerID: String
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
        id: String,
        ownerID: String,
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
        self.ownerID = ownerID
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
        case ownerID = "owner_id"
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

/// Payload for updating mutable cat fields.
public struct SupabaseCatUpdatePayload: Codable, Sendable {
    public let name: String
    public let breed: String?
    public let estimatedAge: String?
    public let locationName: String?
    public let locationLat: Double?
    public let locationLng: Double?
    public let notes: String?
    public let isOwned: Bool
    public let photoUrls: [String]

    public init(
        name: String,
        breed: String?,
        estimatedAge: String?,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        notes: String?,
        isOwned: Bool,
        photoUrls: [String]
    ) {
        self.name = name
        self.breed = breed
        self.estimatedAge = estimatedAge
        self.locationName = locationName
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.notes = notes
        self.isOwned = isOwned
        self.photoUrls = photoUrls
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case breed
        case estimatedAge = "estimated_age"
        case locationName = "location_name"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case notes
        case isOwned = "is_owned"
        case photoUrls = "photo_urls"
    }
}
