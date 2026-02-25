import Foundation

struct CloudEncounter: Sendable {
    let recordName: String
    let ownerID: String
    let catRecordName: String
    let date: Date
    let locationName: String
    let locationLatitude: Double?
    let locationLongitude: Double?
    let notes: String
    let photos: [Data]
}
