import Foundation
import CatchCore

struct CatDisplayData: Identifiable, Hashable {
    let id: String
    let name: String
    let breed: String
    let estimatedAge: String
    let locationName: String
    let notes: String
    let isOwned: Bool
    let isUnnamed: Bool
    let isSteven: Bool
    let createdAt: Date
    let encounterCount: Int
    let firstPhotoUrl: String?

    // MARK: - Local init

    init(local cat: Cat, encounterCount: Int? = nil) {
        self.id = cat.id.uuidString
        self.name = cat.displayName
        self.breed = cat.breed ?? ""
        self.estimatedAge = cat.estimatedAge
        self.locationName = cat.location.name
        self.notes = cat.notes
        self.isOwned = cat.isOwned
        self.isUnnamed = cat.isUnnamed
        self.isSteven = cat.isSteven
        self.createdAt = cat.createdAt
        self.encounterCount = encounterCount ?? cat.encounters.count
        self.firstPhotoUrl = cat.photoUrls.first
    }

    // MARK: - Remote CloudKit init

    init(remote cat: CloudCat, encounterCount: Int) {
        self.id = cat.recordName
        self.name = cat.displayName
        self.breed = cat.breed
        self.estimatedAge = cat.estimatedAge
        self.locationName = cat.locationName
        self.notes = cat.notes
        self.isOwned = cat.isOwned
        self.isUnnamed = cat.isUnnamed
        self.isSteven = false
        self.createdAt = cat.createdAt
        self.encounterCount = encounterCount
        self.firstPhotoUrl = cat.photoUrls.first
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(encounterCount)
    }

    static func == (lhs: CatDisplayData, rhs: CatDisplayData) -> Bool {
        lhs.id == rhs.id
            && lhs.encounterCount == rhs.encounterCount
            && lhs.name == rhs.name
            && lhs.breed == rhs.breed
            && lhs.isOwned == rhs.isOwned
    }
}
