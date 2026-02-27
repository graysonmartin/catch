import Foundation

public struct EncounterComment: Sendable, Equatable, Identifiable {
    public let id: String
    public let encounterRecordName: String
    public let userID: String
    public let text: String
    public let createdAt: Date

    public init(id: String, encounterRecordName: String, userID: String, text: String, createdAt: Date) {
        self.id = id
        self.encounterRecordName = encounterRecordName
        self.userID = userID
        self.text = text
        self.createdAt = createdAt
    }
}
