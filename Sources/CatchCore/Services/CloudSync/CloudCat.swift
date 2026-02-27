import Foundation

public struct CloudCat: Sendable {
    public let recordName: String
    public let ownerID: String
    public let name: String?
    public let breed: String
    public let estimatedAge: String
    public let locationName: String
    public let locationLatitude: Double?
    public let locationLongitude: Double?
    public let notes: String
    public let isOwned: Bool
    public let createdAt: Date
    public let photos: [Data]

    public var isUnnamed: Bool {
        name?.isEmpty ?? true
    }

    public var displayName: String {
        if let name, !name.isEmpty {
            return name
        }
        return CatchStrings.Common.unnamedCatFallback
    }

    public init(
        recordName: String,
        ownerID: String,
        name: String?,
        breed: String,
        estimatedAge: String,
        locationName: String,
        locationLatitude: Double?,
        locationLongitude: Double?,
        notes: String,
        isOwned: Bool,
        createdAt: Date,
        photos: [Data]
    ) {
        self.recordName = recordName
        self.ownerID = ownerID
        self.name = name
        self.breed = breed
        self.estimatedAge = estimatedAge
        self.locationName = locationName
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.notes = notes
        self.isOwned = isOwned
        self.createdAt = createdAt
        self.photos = photos
    }
}
