import Foundation

/// Lightweight projection of a `CloudEncounter` + `CloudCat` for display on feed cards.
/// Extracts only the fields needed for rendering, keeping heavy photo data as-is
/// (views are responsible for lazy-loading / downsampling).
public struct FeedEncounterDetail: Sendable {
    public let recordName: String
    public let catName: String
    public let breed: String
    public let isUnnamed: Bool
    public let isOwned: Bool
    public let date: Date
    public let locationName: String
    public let notes: String
    public let encounterPhotos: [Data]
    public let catPhotos: [Data]
    public let encounterPhotoUrls: [String]
    public let catPhotoUrls: [String]
    public let isFirstEncounter: Bool

    public init(
        recordName: String,
        catName: String,
        breed: String,
        isUnnamed: Bool,
        isOwned: Bool,
        date: Date,
        locationName: String,
        notes: String,
        encounterPhotos: [Data],
        catPhotos: [Data],
        encounterPhotoUrls: [String] = [],
        catPhotoUrls: [String] = [],
        isFirstEncounter: Bool
    ) {
        self.recordName = recordName
        self.catName = catName
        self.breed = breed
        self.isUnnamed = isUnnamed
        self.isOwned = isOwned
        self.date = date
        self.locationName = locationName
        self.notes = notes
        self.encounterPhotos = encounterPhotos
        self.catPhotos = catPhotos
        self.encounterPhotoUrls = encounterPhotoUrls
        self.catPhotoUrls = catPhotoUrls
        self.isFirstEncounter = isFirstEncounter
    }

    /// Photos to display: encounter-specific photos if available, otherwise cat photos.
    public var displayPhotos: [Data] {
        encounterPhotos.isEmpty ? catPhotos : encounterPhotos
    }

    /// Photo URLs to display: encounter URLs if available, otherwise cat URLs.
    public var displayPhotoUrls: [String] {
        encounterPhotoUrls.isEmpty ? catPhotoUrls : encounterPhotoUrls
    }

    /// First cat photo for thumbnail display, or nil.
    public var thumbnailPhoto: Data? {
        catPhotos.first
    }

    /// First cat photo URL for thumbnail display, or nil.
    public var thumbnailPhotoUrl: String? {
        catPhotoUrls.first
    }
}
