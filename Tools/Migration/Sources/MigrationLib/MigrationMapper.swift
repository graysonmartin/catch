import Foundation

/// Converts CloudKit export models to Supabase insert payloads.
///
/// All ID mapping (Apple user ID to Supabase UUID, CK record name to Supabase UUID) is handled
/// through the provided parameters, keeping the mapper stateless and testable.
public enum MigrationMapper {

    // MARK: - Profile

    public struct ProfileInsert: Codable, Sendable, Equatable {
        public let id: String
        public let displayName: String
        public let username: String
        public let bio: String
        public let isPrivate: Bool
        public let showCats: Bool
        public let showEncounters: Bool
        public let avatarUrl: String?

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

    public static func mapProfile(
        _ profile: CKExportProfile,
        supabaseUserID: String
    ) -> ProfileInsert {
        let username: String
        if let existing = profile.username, !existing.isEmpty {
            username = existing
        } else {
            username = String(profile.appleUserID.prefix(12)).lowercased() + "_migrated"
        }

        return ProfileInsert(
            id: supabaseUserID,
            displayName: profile.displayName,
            username: username,
            bio: profile.bio,
            isPrivate: profile.isPrivate,
            showCats: true,
            showEncounters: true,
            avatarUrl: nil
        )
    }

    // MARK: - Cat

    public struct CatInsert: Codable, Sendable, Equatable {
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

    /// Maps a CloudKit cat to a Supabase insert payload.
    public static func mapCat(
        _ cat: CKExportCat,
        supabaseOwnerID: String,
        supabaseCatID: String,
        photoUrls: [String]
    ) -> CatInsert {
        CatInsert(
            id: supabaseCatID,
            ownerID: supabaseOwnerID,
            name: cat.name ?? "",
            breed: cat.breed.isEmpty ? nil : cat.breed,
            estimatedAge: cat.estimatedAge.isEmpty ? nil : cat.estimatedAge,
            locationName: cat.locationName.isEmpty ? nil : cat.locationName,
            locationLat: cat.locationLatitude,
            locationLng: cat.locationLongitude,
            notes: cat.notes.isEmpty ? nil : cat.notes,
            isOwned: cat.isOwned,
            photoUrls: photoUrls,
            createdAt: cat.createdAt
        )
    }

    // MARK: - Encounter

    public struct EncounterInsert: Codable, Sendable, Equatable {
        public let id: String
        public let ownerID: String
        public let catID: String
        public let date: Date
        public let locationName: String?
        public let locationLat: Double?
        public let locationLng: Double?
        public let notes: String?
        public let photoUrls: [String]

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

    /// Maps a CloudKit encounter to a Supabase insert payload.
    public static func mapEncounter(
        _ encounter: CKExportEncounter,
        supabaseOwnerID: String,
        supabaseEncounterID: String,
        supabaseCatID: String,
        photoUrls: [String]
    ) -> EncounterInsert {
        EncounterInsert(
            id: supabaseEncounterID,
            ownerID: supabaseOwnerID,
            catID: supabaseCatID,
            date: encounter.date,
            locationName: encounter.locationName.isEmpty ? nil : encounter.locationName,
            locationLat: encounter.locationLatitude,
            locationLng: encounter.locationLongitude,
            notes: encounter.notes.isEmpty ? nil : encounter.notes,
            photoUrls: photoUrls
        )
    }

    // MARK: - Follow

    public struct FollowInsert: Codable, Sendable, Equatable {
        public let followerID: String
        public let followeeID: String
        public let status: String

        private enum CodingKeys: String, CodingKey {
            case followerID = "follower_id"
            case followeeID = "followee_id"
            case status
        }
    }

    /// Maps a CloudKit follow to a Supabase insert payload.
    public static func mapFollow(
        _ follow: CKExportFollow,
        supabaseFollowerID: String,
        supabaseFolloweeID: String
    ) -> FollowInsert {
        FollowInsert(
            followerID: supabaseFollowerID,
            followeeID: supabaseFolloweeID,
            status: follow.status
        )
    }

    // MARK: - Like

    public struct LikeInsert: Codable, Sendable, Equatable {
        public let encounterID: String
        public let userID: String

        private enum CodingKeys: String, CodingKey {
            case encounterID = "encounter_id"
            case userID = "user_id"
        }
    }

    /// Maps a CloudKit like to a Supabase insert payload.
    public static func mapLike(
        _ like: CKExportLike,
        supabaseUserID: String,
        supabaseEncounterID: String
    ) -> LikeInsert {
        LikeInsert(
            encounterID: supabaseEncounterID,
            userID: supabaseUserID
        )
    }

    // MARK: - Comment

    public struct CommentInsert: Codable, Sendable, Equatable {
        public let encounterID: String
        public let userID: String
        public let text: String

        private enum CodingKeys: String, CodingKey {
            case encounterID = "encounter_id"
            case userID = "user_id"
            case text
        }
    }

    /// Maps a CloudKit comment to a Supabase insert payload.
    public static func mapComment(
        _ comment: CKExportComment,
        supabaseUserID: String,
        supabaseEncounterID: String
    ) -> CommentInsert {
        CommentInsert(
            encounterID: supabaseEncounterID,
            userID: supabaseUserID,
            text: comment.text
        )
    }
}
