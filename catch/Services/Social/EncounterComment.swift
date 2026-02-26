import Foundation

struct EncounterComment: Sendable, Equatable, Identifiable {
    let id: String
    let encounterRecordName: String
    let userID: String
    let text: String
    let createdAt: Date
}
