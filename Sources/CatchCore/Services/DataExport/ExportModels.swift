import Foundation

// MARK: - Top-Level Export Container

public struct ExportData: Codable, Sendable, Equatable {
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

// MARK: - Exported Cat

public struct ExportCat: Codable, Sendable, Equatable {
    public let name: String?
    public let breed: String?
    public let estimatedAge: String
    public let location: Location
    public let notes: String
    public let isOwned: Bool
    public let createdAt: Date
    public let encounters: [ExportEncounter]

    public init(
        name: String?,
        breed: String?,
        estimatedAge: String,
        location: Location,
        notes: String,
        isOwned: Bool,
        createdAt: Date,
        encounters: [ExportEncounter]
    ) {
        self.name = name
        self.breed = breed
        self.estimatedAge = estimatedAge
        self.location = location
        self.notes = notes
        self.isOwned = isOwned
        self.createdAt = createdAt
        self.encounters = encounters
    }
}

// MARK: - Exported Encounter

public struct ExportEncounter: Codable, Sendable, Equatable {
    public let date: Date
    public let location: Location
    public let notes: String

    public init(
        date: Date,
        location: Location,
        notes: String
    ) {
        self.date = date
        self.location = location
        self.notes = notes
    }
}
