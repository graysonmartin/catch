import Foundation

/// Pure-logic mapper that converts cloud domain models into restore-ready structs.
/// These structs contain all the data needed to create local SwiftData models,
/// without depending on SwiftData itself.
public enum RestoreMapper {

    /// A flat representation of a cat ready for local insertion.
    public struct RestoredCat: Sendable, Equatable {
        public let cloudKitRecordName: String
        public let name: String?
        public let breed: String
        public let estimatedAge: String
        public let location: Location
        public let notes: String
        public let isOwned: Bool
        public let createdAt: Date
        public let photos: [Data]

        public init(
            cloudKitRecordName: String,
            name: String?,
            breed: String,
            estimatedAge: String,
            location: Location,
            notes: String,
            isOwned: Bool,
            createdAt: Date,
            photos: [Data]
        ) {
            self.cloudKitRecordName = cloudKitRecordName
            self.name = name
            self.breed = breed
            self.estimatedAge = estimatedAge
            self.location = location
            self.notes = notes
            self.isOwned = isOwned
            self.createdAt = createdAt
            self.photos = photos
        }
    }

    /// A flat representation of an encounter ready for local insertion.
    public struct RestoredEncounter: Sendable, Equatable {
        public let cloudKitRecordName: String
        public let catRecordName: String
        public let date: Date
        public let location: Location
        public let notes: String
        public let photos: [Data]

        public init(
            cloudKitRecordName: String,
            catRecordName: String,
            date: Date,
            location: Location,
            notes: String,
            photos: [Data]
        ) {
            self.cloudKitRecordName = cloudKitRecordName
            self.catRecordName = catRecordName
            self.date = date
            self.location = location
            self.notes = notes
            self.photos = photos
        }
    }

    // MARK: - Mapping

    public static func mapCat(_ cloudCat: CloudCat) -> RestoredCat {
        let location = Location(
            name: cloudCat.locationName,
            latitude: cloudCat.locationLatitude,
            longitude: cloudCat.locationLongitude
        )
        return RestoredCat(
            cloudKitRecordName: cloudCat.recordName,
            name: cloudCat.name,
            breed: cloudCat.breed,
            estimatedAge: cloudCat.estimatedAge,
            location: location,
            notes: cloudCat.notes,
            isOwned: cloudCat.isOwned,
            createdAt: cloudCat.createdAt,
            photos: cloudCat.photos
        )
    }

    public static func mapEncounter(_ cloudEncounter: CloudEncounter) -> RestoredEncounter {
        let location = Location(
            name: cloudEncounter.locationName,
            latitude: cloudEncounter.locationLatitude,
            longitude: cloudEncounter.locationLongitude
        )
        return RestoredEncounter(
            cloudKitRecordName: cloudEncounter.recordName,
            catRecordName: cloudEncounter.catRecordName,
            date: cloudEncounter.date,
            location: location,
            notes: cloudEncounter.notes,
            photos: cloudEncounter.photos
        )
    }

    /// Maps arrays of CloudCat and CloudEncounter into restore-ready structs,
    /// grouping encounters by their parent cat record name.
    public static func mapAll(
        cats: [CloudCat],
        encounters: [CloudEncounter]
    ) -> (cats: [RestoredCat], encounters: [RestoredEncounter]) {
        let restoredCats = cats.map(mapCat)
        let restoredEncounters = encounters.map(mapEncounter)
        return (restoredCats, restoredEncounters)
    }
}
