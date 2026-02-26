import Foundation

struct CatSyncPayload: Sendable {
    let recordName: String?
    let name: String
    let breed: String?
    let estimatedAge: String
    let locationName: String
    let locationLatitude: Double?
    let locationLongitude: Double?
    let notes: String
    let isOwned: Bool
    let createdAt: Date
    let photos: [Data]
    var personalityLabels: [String] = []
}
