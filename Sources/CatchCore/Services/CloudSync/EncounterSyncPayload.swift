import Foundation

public struct EncounterSyncPayload: Sendable {
    public let recordName: String?
    public let catRecordName: String
    public let date: Date
    public let locationName: String
    public let locationLatitude: Double?
    public let locationLongitude: Double?
    public let notes: String
    public let photos: [Data]

    public init(
        recordName: String?,
        catRecordName: String,
        date: Date,
        locationName: String,
        locationLatitude: Double?,
        locationLongitude: Double?,
        notes: String,
        photos: [Data]
    ) {
        self.recordName = recordName
        self.catRecordName = catRecordName
        self.date = date
        self.locationName = locationName
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.notes = notes
        self.photos = photos
    }
}
