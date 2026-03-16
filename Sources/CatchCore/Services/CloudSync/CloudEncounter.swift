import Foundation

public struct CloudEncounter: Sendable {
    public let recordName: String
    public let ownerID: String
    public let catRecordName: String
    public let date: Date
    public let locationName: String
    public let locationLatitude: Double?
    public let locationLongitude: Double?
    public let notes: String
    public let photos: [Data]
    public let photoUrls: [String]

    public init(
        recordName: String,
        ownerID: String,
        catRecordName: String,
        date: Date,
        locationName: String,
        locationLatitude: Double?,
        locationLongitude: Double?,
        notes: String,
        photos: [Data],
        photoUrls: [String] = []
    ) {
        self.recordName = recordName
        self.ownerID = ownerID
        self.catRecordName = catRecordName
        self.date = date
        self.locationName = locationName
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.notes = notes
        self.photos = photos
        self.photoUrls = photoUrls
    }
}
