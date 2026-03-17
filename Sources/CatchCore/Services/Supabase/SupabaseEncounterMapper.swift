import Foundation

/// Maps between `SupabaseEncounter` rows and `CloudEncounter` domain models.
public enum SupabaseEncounterMapper {

    /// Converts a Supabase encounter row to the shared `CloudEncounter` domain model.
    /// Photo URLs are not resolved to `Data` here — callers handle asset loading.
    public static func toCloudEncounter(_ encounter: SupabaseEncounter) -> CloudEncounter {
        CloudEncounter(
            recordName: encounter.id.uuidString.lowercased(),
            ownerID: encounter.ownerID.uuidString.lowercased(),
            catRecordName: encounter.catID.uuidString.lowercased(),
            date: encounter.date,
            locationName: encounter.locationName ?? "",
            locationLatitude: encounter.locationLat,
            locationLongitude: encounter.locationLng,
            notes: encounter.notes ?? "",
            photos: [],
            photoUrls: encounter.photoUrls
        )
    }

    /// Builds an insert payload from an `EncounterSyncPayload` and owner ID.
    static func insertPayload(
        from payload: EncounterSyncPayload,
        ownerID: String,
        recordName: String
    ) -> SupabaseEncounterInsertPayload {
        SupabaseEncounterInsertPayload(
            id: recordName,
            ownerID: ownerID,
            catID: payload.catRecordName,
            date: payload.date,
            locationName: payload.locationName.isEmpty ? nil : payload.locationName,
            locationLat: payload.locationLatitude,
            locationLng: payload.locationLongitude,
            notes: payload.notes.isEmpty ? nil : payload.notes,
            photoUrls: []
        )
    }

    /// Builds an update payload from an `EncounterSyncPayload`.
    static func updatePayload(from payload: EncounterSyncPayload) -> SupabaseEncounterUpdatePayload {
        SupabaseEncounterUpdatePayload(
            date: payload.date,
            locationName: payload.locationName.isEmpty ? nil : payload.locationName,
            locationLat: payload.locationLatitude,
            locationLng: payload.locationLongitude,
            notes: payload.notes.isEmpty ? nil : payload.notes,
            photoUrls: []
        )
    }
}
