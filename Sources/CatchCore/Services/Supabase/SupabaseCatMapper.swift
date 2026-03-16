import Foundation

/// Maps between `SupabaseCat` rows and `CloudCat` domain models.
public enum SupabaseCatMapper {

    /// Converts a Supabase cat row to the shared `CloudCat` domain model.
    /// Photo URLs are not resolved to `Data` here — callers handle asset loading.
    public static func toCloudCat(_ cat: SupabaseCat) -> CloudCat {
        CloudCat(
            recordName: cat.id.uuidString,
            ownerID: cat.ownerID.uuidString,
            name: cat.name.isEmpty ? nil : cat.name,
            breed: cat.breed ?? "",
            estimatedAge: cat.estimatedAge ?? "",
            locationName: cat.locationName ?? "",
            locationLatitude: cat.locationLat,
            locationLongitude: cat.locationLng,
            notes: cat.notes ?? "",
            isOwned: cat.isOwned,
            createdAt: cat.createdAt,
            photos: []
        )
    }

    /// Builds an insert payload from a `CatSyncPayload` and owner ID.
    static func insertPayload(
        from payload: CatSyncPayload,
        ownerID: String,
        recordName: String
    ) -> SupabaseCatInsertPayload {
        SupabaseCatInsertPayload(
            id: recordName,
            ownerID: ownerID,
            name: payload.name ?? "",
            breed: payload.breed,
            estimatedAge: payload.estimatedAge.isEmpty ? nil : payload.estimatedAge,
            locationName: payload.locationName.isEmpty ? nil : payload.locationName,
            locationLat: payload.locationLatitude,
            locationLng: payload.locationLongitude,
            notes: payload.notes.isEmpty ? nil : payload.notes,
            isOwned: payload.isOwned,
            photoUrls: [],
            createdAt: payload.createdAt
        )
    }

    /// Builds an update payload from a `CatSyncPayload`.
    static func updatePayload(from payload: CatSyncPayload) -> SupabaseCatUpdatePayload {
        SupabaseCatUpdatePayload(
            name: payload.name ?? "",
            breed: payload.breed,
            estimatedAge: payload.estimatedAge.isEmpty ? nil : payload.estimatedAge,
            locationName: payload.locationName.isEmpty ? nil : payload.locationName,
            locationLat: payload.locationLatitude,
            locationLng: payload.locationLongitude,
            notes: payload.notes.isEmpty ? nil : payload.notes,
            isOwned: payload.isOwned,
            photoUrls: []
        )
    }
}
