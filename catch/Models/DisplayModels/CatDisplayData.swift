import Foundation

struct CatDisplayData: Identifiable, Hashable {
    let id: String
    let name: String
    let breed: String
    let estimatedAge: String
    let locationName: String
    let notes: String
    let isOwned: Bool
    let isSteven: Bool
    let createdAt: Date
    let encounterCount: Int
    let firstPhotoData: Data?
    let allPhotos: [Data]

    // MARK: - Local SwiftData init

    init(local cat: Cat) {
        self.id = cat.persistentModelID.hashValue.description
        self.name = cat.displayName
        self.breed = cat.breed ?? ""
        self.estimatedAge = cat.estimatedAge
        self.locationName = cat.location.name
        self.notes = cat.notes
        self.isOwned = cat.isOwned
        self.isSteven = cat.isSteven
        self.createdAt = cat.createdAt
        self.encounterCount = cat.encounters.count
        self.firstPhotoData = cat.photos.first
        self.allPhotos = cat.photos
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
        self.isSteven = false
        self.createdAt = cat.createdAt
        self.encounterCount = encounterCount
        self.firstPhotoData = cat.photos.first
        self.allPhotos = cat.photos
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CatDisplayData, rhs: CatDisplayData) -> Bool {
        lhs.id == rhs.id
    }
}
