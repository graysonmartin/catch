import Foundation

struct CloudCat: Sendable {
    let recordName: String
    let ownerID: String
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
