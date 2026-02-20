import Foundation

struct CatSyncPayload: Sendable {
    let recordName: String?
    let name: String
    let estimatedAge: String
    let locationName: String
    let locationLatitude: Double?
    let locationLongitude: Double?
    let notes: String
    let isOwned: Bool
    let createdAt: Date
    let photos: [Data]
}

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
