import Foundation
import SwiftData
import CatchCore

@Model
final class Cat {
    var name: String?
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

    init(
        name: String? = nil,
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
}
