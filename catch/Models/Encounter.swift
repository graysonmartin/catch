import Foundation
import CatchCore

struct Encounter: Identifiable, Hashable, Sendable {
    let id: UUID
    var date: Date
    var location: Location
    var notes: String
    var catID: UUID?
    var ownerID: UUID
    var photoUrls: [String]
    var likeCount: Int
    var commentCount: Int
    var createdAt: Date

    /// Populated client-side after fetch, not stored in Supabase.
    var cat: Cat?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        location: Location = .empty,
        notes: String = "",
        catID: UUID? = nil,
        ownerID: UUID = UUID(),
        photoUrls: [String] = [],
        likeCount: Int = 0,
        commentCount: Int = 0,
        createdAt: Date = Date(),
        cat: Cat? = nil
    ) {
        self.id = id
        self.date = date
        self.location = location
        self.notes = notes
        self.catID = catID
        self.ownerID = ownerID
        self.photoUrls = photoUrls
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.createdAt = createdAt
        self.cat = cat
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Encounter, rhs: Encounter) -> Bool {
        lhs.id == rhs.id
            && lhs.date == rhs.date
            && lhs.location == rhs.location
            && lhs.notes == rhs.notes
            && lhs.photoUrls == rhs.photoUrls
            && lhs.likeCount == rhs.likeCount
            && lhs.commentCount == rhs.commentCount
    }

    // MARK: - Supabase Mapping

    init(supabase encounter: SupabaseEncounter, cat: Cat? = nil) {
        self.id = encounter.id
        self.date = encounter.date
        self.location = Location(
            name: encounter.locationName ?? "",
            latitude: encounter.locationLat,
            longitude: encounter.locationLng
        )
        self.notes = encounter.notes ?? ""
        self.catID = encounter.catID
        self.ownerID = encounter.ownerID
        self.photoUrls = encounter.photoUrls
        self.likeCount = encounter.likeCount
        self.commentCount = encounter.commentCount
        self.createdAt = encounter.createdAt
        self.cat = cat
    }

    func toInsertPayload(ownerID: String) -> SupabaseEncounterInsertPayload {
        SupabaseEncounterInsertPayload(
            id: id.uuidString,
            ownerID: ownerID,
            catID: (catID ?? cat?.id ?? UUID()).uuidString,
            date: date,
            locationName: location.name.isEmpty ? nil : location.name,
            locationLat: location.latitude,
            locationLng: location.longitude,
            notes: notes.isEmpty ? nil : notes,
            photoUrls: photoUrls
        )
    }

    func toUpdatePayload() -> SupabaseEncounterUpdatePayload {
        SupabaseEncounterUpdatePayload(
            date: date,
            locationName: location.name.isEmpty ? nil : location.name,
            locationLat: location.latitude,
            locationLng: location.longitude,
            notes: notes.isEmpty ? nil : notes,
            photoUrls: photoUrls
        )
    }
}
