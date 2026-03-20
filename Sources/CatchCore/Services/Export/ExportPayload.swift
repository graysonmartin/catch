import Foundation

/// Top-level container for a Catch data export file.
public struct ExportPayload: Codable, Sendable, Equatable {
    public let version: Int
    public let exportedAt: Date
    public let cats: [ExportCat]

    public init(
        version: Int = 1,
        exportedAt: Date = Date(),
        cats: [ExportCat]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.cats = cats
    }
}

/// Lightweight DTO for a cat in an export file.
public struct ExportCat: Codable, Sendable, Equatable {
    public let id: String
    public let name: String?
    public let breed: String?
    public let estimatedAge: String?
    public let locationName: String?
    public let locationLat: Double?
    public let locationLng: Double?
    public let notes: String?
    public let isOwned: Bool
    public let photoUrls: [String]
    public let createdAt: Date
    public let encounters: [ExportEncounter]

    public init(
        id: String,
        name: String?,
        breed: String?,
        estimatedAge: String?,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        notes: String?,
        isOwned: Bool,
        photoUrls: [String],
        createdAt: Date,
        encounters: [ExportEncounter]
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.estimatedAge = estimatedAge
        self.locationName = locationName
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.notes = notes
        self.isOwned = isOwned
        self.photoUrls = photoUrls
        self.createdAt = createdAt
        self.encounters = encounters
    }
}

/// Lightweight DTO for an encounter in an export file.
public struct ExportEncounter: Codable, Sendable, Equatable {
    public let id: String
    public let date: Date
    public let locationName: String?
    public let locationLat: Double?
    public let locationLng: Double?
    public let notes: String?
    public let photoUrls: [String]
    public let createdAt: Date

    public init(
        id: String,
        date: Date,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        notes: String?,
        photoUrls: [String],
        createdAt: Date
    ) {
        self.id = id
        self.date = date
        self.locationName = locationName
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.notes = notes
        self.photoUrls = photoUrls
        self.createdAt = createdAt
    }
}
