import Foundation

/// Maps `SupabaseFeedRow` joined rows to domain models used by the feed.
public enum SupabaseFeedMapper {

    /// Converts a feed row's encounter data to a `CloudEncounter`.
    public static func toCloudEncounter(_ row: SupabaseFeedRow) -> CloudEncounter {
        CloudEncounter(
            recordName: row.id.uuidString.lowercased(),
            ownerID: row.ownerID.uuidString.lowercased(),
            catRecordName: row.catID.uuidString.lowercased(),
            date: row.date,
            locationName: row.locationName ?? "",
            locationLatitude: row.locationLat,
            locationLongitude: row.locationLng,
            notes: row.notes ?? "",
            photos: [],
            photoUrls: row.photoUrls
        )
    }

    /// Converts a feed row's nested cat data to a `CloudCat`.
    public static func toCloudCat(_ cat: SupabaseFeedCat, ownerID: String) -> CloudCat {
        CloudCat(
            recordName: cat.id.uuidString.lowercased(),
            ownerID: ownerID,
            name: cat.name.isEmpty ? nil : cat.name,
            breed: cat.breed ?? "",
            estimatedAge: cat.estimatedAge ?? "",
            locationName: cat.locationName ?? "",
            locationLatitude: cat.locationLat,
            locationLongitude: cat.locationLng,
            notes: cat.notes ?? "",
            isOwned: cat.isOwned,
            createdAt: cat.createdAt,
            photos: [],
            photoUrls: cat.photoUrls
        )
    }

    /// Converts a feed row's nested profile data to a `CloudUserProfile`.
    public static func toCloudUserProfile(_ profile: SupabaseFeedProfile) -> CloudUserProfile {
        CloudUserProfile(
            recordName: profile.id.uuidString.lowercased(),
            appleUserID: profile.id.uuidString.lowercased(),
            displayName: profile.displayName,
            bio: profile.bio,
            username: profile.username,
            isPrivate: profile.isPrivate,
            avatarData: nil,
            avatarURL: profile.avatarUrl
        )
    }
}
