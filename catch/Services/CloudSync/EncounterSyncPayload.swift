import Foundation

struct EncounterSyncPayload: Sendable {
    let recordName: String?
    let catRecordName: String
    let date: Date
    let locationName: String
    let locationLatitude: Double?
    let locationLongitude: Double?
    let notes: String
    let photos: [Data]
}
