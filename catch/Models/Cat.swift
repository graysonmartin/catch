import Foundation
import CatchCore

struct Cat: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String?
    var breed: String?
    var estimatedAge: String
    var location: Location
    var notes: String
    var isOwned: Bool
    var createdAt: Date
    var photoUrls: [String]
    var encounters: [Encounter]
    var ownerID: UUID

    init(
        id: UUID = UUID(),
        name: String? = nil,
        breed: String? = nil,
        estimatedAge: String = "",
        location: Location = .empty,
        notes: String = "",
        isOwned: Bool = false,
        photoUrls: [String] = [],
        encounters: [Encounter] = [],
        ownerID: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.estimatedAge = estimatedAge
        self.location = location
        self.notes = notes
        self.isOwned = isOwned
        self.createdAt = createdAt
        self.photoUrls = photoUrls
        self.encounters = encounters
        self.ownerID = ownerID
    }

    var isUnnamed: Bool {
        name?.isEmpty ?? true
    }

    var displayName: String {
        if let name, !name.isEmpty {
            return name
        }
        return CatchStrings.Common.unnamedCatFallback
    }

    var lastEncounterDate: Date? {
        encounters.map(\.date).max()
    }

    private static let stevenNames: Set<String> = ["steven", "stephen", "steve"]
    private static let stevenBreeds: Set<String> = ["Domestic Shorthair"]

    var isSteven: Bool {
        guard let name else { return false }
        return Self.stevenNames.contains(name.trimmingCharacters(in: .whitespaces).lowercased())
            && Self.stevenBreeds.contains(breed ?? "")
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Cat, rhs: Cat) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Supabase Mapping

    init(supabase cat: SupabaseCat, encounters: [Encounter] = []) {
        self.id = cat.id
        self.name = cat.name.isEmpty ? nil : cat.name
        self.breed = cat.breed
        self.estimatedAge = cat.estimatedAge ?? ""
        self.location = Location(
            name: cat.locationName ?? "",
            latitude: cat.locationLat,
            longitude: cat.locationLng
        )
        self.notes = cat.notes ?? ""
        self.isOwned = cat.isOwned
        self.createdAt = cat.createdAt
        self.photoUrls = cat.photoUrls
        self.encounters = encounters
        self.ownerID = cat.ownerID
    }

    func toInsertPayload(ownerID: String) -> SupabaseCatInsertPayload {
        SupabaseCatInsertPayload(
            id: id.uuidString,
            ownerID: ownerID,
            name: name ?? "",
            breed: breed,
            estimatedAge: estimatedAge.isEmpty ? nil : estimatedAge,
            locationName: location.name.isEmpty ? nil : location.name,
            locationLat: location.latitude,
            locationLng: location.longitude,
            notes: notes.isEmpty ? nil : notes,
            isOwned: isOwned,
            photoUrls: photoUrls,
            createdAt: createdAt
        )
    }

    func toUpdatePayload() -> SupabaseCatUpdatePayload {
        SupabaseCatUpdatePayload(
            name: name ?? "",
            breed: breed,
            estimatedAge: estimatedAge.isEmpty ? nil : estimatedAge,
            locationName: location.name.isEmpty ? nil : location.name,
            locationLat: location.latitude,
            locationLng: location.longitude,
            notes: notes.isEmpty ? nil : notes,
            isOwned: isOwned,
            photoUrls: photoUrls
        )
    }
}
