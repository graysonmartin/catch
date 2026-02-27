import Foundation

public struct EncounterLike: Sendable, Equatable, Identifiable {
    public let id: String
    public let encounterRecordName: String
    public let userID: String
    public let createdAt: Date

    public init(id: String, encounterRecordName: String, userID: String, createdAt: Date) {
        self.id = id
        self.encounterRecordName = encounterRecordName
        self.userID = userID
        self.createdAt = createdAt
    }
}
