import Foundation
import SwiftData

@Model
final class Cat {
    var name: String
    var estimatedAge: String
    var location: Location
    var notes: String
    var isOwned: Bool
    var createdAt: Date

    @Attribute(.externalStorage)
    var photos: [Data]

    @Relationship(deleteRule: .cascade, inverse: \Encounter.cat)
    var encounters: [Encounter]

    @Relationship(deleteRule: .cascade, inverse: \CareEntry.cat)
    var careEntries: [CareEntry]

    init(
        name: String,
        estimatedAge: String = "",
        location: Location = .empty,
        notes: String = "",
        isOwned: Bool = false,
        photos: [Data] = []
    ) {
        self.name = name
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
}
