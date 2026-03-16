import Foundation

/// JSON-decodable representations of CloudKit export data.
/// These mirror the CloudKit record types and are decoded from the export JSON files
/// that can be generated via the CloudKit Dashboard export or a custom export script.

public struct CKExportProfile: Codable, Sendable, Equatable {
    public let recordName: String
    public let appleUserID: String
    public let displayName: String
    public let bio: String
    public let username: String?
    public let isPrivate: Bool
    public let avatarURL: String?

    public init(
        recordName: String,
        appleUserID: String,
        displayName: String,
        bio: String,
        username: String?,
        isPrivate: Bool,
        avatarURL: String?
    ) {
        self.recordName = recordName
        self.appleUserID = appleUserID
        self.displayName = displayName
        self.bio = bio
        self.username = username
        self.isPrivate = isPrivate
        self.avatarURL = avatarURL
    }

    private enum CodingKeys: String, CodingKey {
        case recordName = "record_name"
        case appleUserID = "apple_user_id"
        case displayName = "display_name"
        case bio
        case username
        case isPrivate = "is_private"
        case avatarURL = "avatar_url"
    }
}

public struct CKExportCat: Codable, Sendable, Equatable {
    public let recordName: String
    public let ownerID: String
    public let name: String?
    public let breed: String
    public let estimatedAge: String
    public let locationName: String
    public let locationLatitude: Double?
    public let locationLongitude: Double?
    public let notes: String
    public let isOwned: Bool
    public let createdAt: Date
    public let photoURLs: [String]

    public init(
        recordName: String,
        ownerID: String,
        name: String?,
        breed: String,
        estimatedAge: String,
        locationName: String,
        locationLatitude: Double?,
        locationLongitude: Double?,
        notes: String,
        isOwned: Bool,
        createdAt: Date,
        photoURLs: [String]
    ) {
        self.recordName = recordName
        self.ownerID = ownerID
        self.name = name
        self.breed = breed
        self.estimatedAge = estimatedAge
        self.locationName = locationName
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.notes = notes
        self.isOwned = isOwned
        self.createdAt = createdAt
        self.photoURLs = photoURLs
    }

    private enum CodingKeys: String, CodingKey {
        case recordName = "record_name"
        case ownerID = "owner_id"
        case name
        case breed
        case estimatedAge = "estimated_age"
        case locationName = "location_name"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case notes
        case isOwned = "is_owned"
        case createdAt = "created_at"
        case photoURLs = "photo_urls"
    }
}

public struct CKExportEncounter: Codable, Sendable, Equatable {
    public let recordName: String
    public let ownerID: String
    public let catRecordName: String
    public let date: Date
    public let locationName: String
    public let locationLatitude: Double?
    public let locationLongitude: Double?
    public let notes: String
    public let photoURLs: [String]

    public init(
        recordName: String,
        ownerID: String,
        catRecordName: String,
        date: Date,
        locationName: String,
        locationLatitude: Double?,
        locationLongitude: Double?,
        notes: String,
        photoURLs: [String]
    ) {
        self.recordName = recordName
        self.ownerID = ownerID
        self.catRecordName = catRecordName
        self.date = date
        self.locationName = locationName
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.notes = notes
        self.photoURLs = photoURLs
    }

    private enum CodingKeys: String, CodingKey {
        case recordName = "record_name"
        case ownerID = "owner_id"
        case catRecordName = "cat_record_name"
        case date
        case locationName = "location_name"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case notes
        case photoURLs = "photo_urls"
    }
}

public struct CKExportFollow: Codable, Sendable, Equatable {
    public let recordName: String
    public let followerID: String
    public let followeeID: String
    public let status: String
    public let createdAt: Date

    public init(
        recordName: String,
        followerID: String,
        followeeID: String,
        status: String,
        createdAt: Date
    ) {
        self.recordName = recordName
        self.followerID = followerID
        self.followeeID = followeeID
        self.status = status
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case recordName = "record_name"
        case followerID = "follower_id"
        case followeeID = "followee_id"
        case status
        case createdAt = "created_at"
    }
}

public struct CKExportLike: Codable, Sendable, Equatable {
    public let recordName: String
    public let encounterRecordName: String
    public let userID: String
    public let createdAt: Date

    public init(
        recordName: String,
        encounterRecordName: String,
        userID: String,
        createdAt: Date
    ) {
        self.recordName = recordName
        self.encounterRecordName = encounterRecordName
        self.userID = userID
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case recordName = "record_name"
        case encounterRecordName = "encounter_record_name"
        case userID = "user_id"
        case createdAt = "created_at"
    }
}

public struct CKExportComment: Codable, Sendable, Equatable {
    public let recordName: String
    public let encounterRecordName: String
    public let userID: String
    public let text: String
    public let createdAt: Date

    public init(
        recordName: String,
        encounterRecordName: String,
        userID: String,
        text: String,
        createdAt: Date
    ) {
        self.recordName = recordName
        self.encounterRecordName = encounterRecordName
        self.userID = userID
        self.text = text
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case recordName = "record_name"
        case encounterRecordName = "encounter_record_name"
        case userID = "user_id"
        case text
        case createdAt = "created_at"
    }
}

/// Top-level container for the full CloudKit data export.
public struct CloudKitExport: Codable, Sendable {
    public let profiles: [CKExportProfile]
    public let cats: [CKExportCat]
    public let encounters: [CKExportEncounter]
    public let follows: [CKExportFollow]
    public let likes: [CKExportLike]
    public let comments: [CKExportComment]

    public init(
        profiles: [CKExportProfile],
        cats: [CKExportCat],
        encounters: [CKExportEncounter],
        follows: [CKExportFollow],
        likes: [CKExportLike],
        comments: [CKExportComment]
    ) {
        self.profiles = profiles
        self.cats = cats
        self.encounters = encounters
        self.follows = follows
        self.likes = likes
        self.comments = comments
    }
}
