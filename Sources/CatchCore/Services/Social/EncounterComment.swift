import Foundation

public struct EncounterComment: Sendable, Equatable, Identifiable {
    public let id: String
    public let encounterRecordName: String
    public let userID: String
    public let text: String
    public let createdAt: Date
    public let isPending: Bool

    public init(
        id: String,
        encounterRecordName: String,
        userID: String,
        text: String,
        createdAt: Date,
        isPending: Bool = false
    ) {
        self.id = id
        self.encounterRecordName = encounterRecordName
        self.userID = userID
        self.text = text
        self.createdAt = createdAt
        self.isPending = isPending
    }

    /// Creates a confirmed copy of a pending comment, replacing the temporary ID.
    public func confirmed(withID serverID: String) -> EncounterComment {
        EncounterComment(
            id: serverID,
            encounterRecordName: encounterRecordName,
            userID: userID,
            text: text,
            createdAt: createdAt,
            isPending: false
        )
    }

    /// Creates a pending (optimistic) comment for immediate UI display.
    public static func pending(
        encounterRecordName: String,
        userID: String,
        text: String
    ) -> EncounterComment {
        EncounterComment(
            id: "pending_\(UUID().uuidString)",
            encounterRecordName: encounterRecordName,
            userID: userID,
            text: text,
            createdAt: Date(),
            isPending: true
        )
    }
}
