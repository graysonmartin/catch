import Foundation

public struct EncounterComment: Sendable, Equatable, Identifiable {
    public let id: String
    public let encounterRecordName: String
    public let userID: String
    public let displayName: String?
    public let username: String?
    public let avatarURL: String?
    public let text: String
    public let createdAt: Date
    public let isPending: Bool

    /// The name shown in the UI — prefers @username, falls back to display name, then truncated userID.
    public var authorName: String {
        if let username {
            return "@\(username)"
        }
        return displayName ?? String(userID.prefix(8))
    }

    public init(
        id: String,
        encounterRecordName: String,
        userID: String,
        displayName: String? = nil,
        username: String? = nil,
        avatarURL: String? = nil,
        text: String,
        createdAt: Date,
        isPending: Bool = false
    ) {
        self.id = id
        self.encounterRecordName = encounterRecordName
        self.userID = userID
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
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
            displayName: displayName,
            username: username,
            avatarURL: avatarURL,
            text: text,
            createdAt: createdAt,
            isPending: false
        )
    }

    /// Creates a pending (optimistic) comment for immediate UI display.
    public static func pending(
        encounterRecordName: String,
        userID: String,
        displayName: String?,
        text: String
    ) -> EncounterComment {
        EncounterComment(
            id: "pending_\(UUID().uuidString)",
            encounterRecordName: encounterRecordName,
            userID: userID,
            displayName: displayName,
            text: text,
            createdAt: Date(),
            isPending: true
        )
    }
}
