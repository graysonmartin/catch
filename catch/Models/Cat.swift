import Foundation
import SwiftData

@Model
final class Cat {
    var name: String
    var breed: String?
    var estimatedAge: String
    var location: Location
    var notes: String
    var isOwned: Bool
    var createdAt: Date
    var cloudKitRecordName: String?

    @Attribute(.externalStorage)
    var photos: [Data]

    @Relationship(deleteRule: .cascade, inverse: \Encounter.cat)
    var encounters: [Encounter]

    @Relationship(deleteRule: .cascade, inverse: \CareEntry.cat)
    var careEntries: [CareEntry]

    init(
        name: String,
        breed: String? = nil,
        estimatedAge: String = "",
        location: Location = .empty,
        notes: String = "",
        isOwned: Bool = false,
        photos: [Data] = []
    ) {
        self.name = name
        self.breed = breed
        self.estimatedAge = estimatedAge
        self.location = location
        self.notes = notes
        self.isOwned = isOwned
        self.createdAt = Date()
        self.photos = photos
        self.encounters = []
        self.careEntries = []
    }

    var lastEncounterDate: Date? {
        encounters.map(\.date).max()
    }

    var isSteven: Bool {
        let stevenNames: Set<String> = ["steven", "stephen", "steve"]
        let tabbyBreeds: Set<String> = ["Tabby", "Tiger Tabby"]
        return stevenNames.contains(name.trimmingCharacters(in: .whitespaces).lowercased())
            && tabbyBreeds.contains(breed ?? "")
    }
}
