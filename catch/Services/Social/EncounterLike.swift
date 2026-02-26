import Foundation

struct EncounterLike: Sendable, Equatable, Identifiable {
    let id: String
    let encounterRecordName: String
    let userID: String
    let createdAt: Date
}
